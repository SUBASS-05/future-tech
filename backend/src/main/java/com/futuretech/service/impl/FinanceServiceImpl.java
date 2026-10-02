package com.futuretech.service.impl;

import com.futuretech.dto.*;
import com.futuretech.entity.Payment;
import com.futuretech.entity.Student;
import com.futuretech.entity.User;
import com.futuretech.entity.enums.FeeStatus;
import com.futuretech.repository.PaymentRepository;
import com.futuretech.repository.StudentRepository;
import com.futuretech.repository.UserRepository;
import com.futuretech.service.FileStorageService;
import com.futuretech.service.FinanceService;
import com.futuretech.util.FeeCycleHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FinanceServiceImpl implements FinanceService {
    private final PaymentRepository paymentRepository;
    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;
    private final com.futuretech.service.WebSocketEventPublisher eventPublisher;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd MMM yyyy");
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("hh:mm a");

    private Student getStudentByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + email));
        return studentRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Student profile not found for user: " + email));
    }

    @Override
    @Transactional(readOnly = true)
    public StudentFeeSummaryResponse getStudentFeeSummary(String email) {
        Student student = getStudentByEmail(email);
        LocalDate joiningDate = FeeCycleHelper.getTuitionJoiningDate(student);
        LocalDate[] cycle = FeeCycleHelper.calculateFeeCycle(joiningDate, LocalDate.now());
        LocalDate cycleStart = cycle[0];
        LocalDate cycleEnd = cycle[1];

        List<Payment> cyclePayments = paymentRepository.findByStudentIdAndFeeCycleStartAndFeeCycleEnd(
                student.getId(), cycleStart, cycleEnd);

        BigDecimal paidAmount = cyclePayments.stream()
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal remainingAmount = FeeCycleHelper.ANNUAL_FEE.subtract(paidAmount);
        if (remainingAmount.compareTo(BigDecimal.ZERO) < 0) {
            remainingAmount = BigDecimal.ZERO;
        }

        FeeStatus status;
        if (paidAmount.compareTo(BigDecimal.ZERO) == 0) {
            status = FeeStatus.PENDING;
        } else if (paidAmount.compareTo(FeeCycleHelper.ANNUAL_FEE) < 0) {
            status = FeeStatus.PARTIALLY_PAID;
        } else {
            status = FeeStatus.PAID;
        }

        List<Payment> allPayments = paymentRepository.findByStudentIdOrderByPaymentDateDesc(student.getId());
        List<PaymentDTO> paymentDTOs = allPayments.stream().map(this::mapToDTO).collect(Collectors.toList());

        return StudentFeeSummaryResponse.builder()
                .annualFee(FeeCycleHelper.ANNUAL_FEE)
                .feeCycleStart(cycleStart)
                .feeCycleEnd(cycleEnd)
                .paidAmount(paidAmount)
                .remainingAmount(remainingAmount)
                .status(status)
                .tuitionJoiningDate(joiningDate)
                .payments(paymentDTOs)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PaymentDTO> getStudentPayments(String email) {
        Student student = getStudentByEmail(email);
        return paymentRepository.findByStudentIdOrderByPaymentDateDesc(student.getId())
                .stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public StudentFeeSummaryResponse submitStudentPayment(String email, BigDecimal amount, MultipartFile file) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Payment amount must be greater than 0");
        }

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Payment proof screenshot is required");
        }

        // Validate file type
        String originalFilename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        if (!originalFilename.endsWith(".jpg") && !originalFilename.endsWith(".jpeg") && !originalFilename.endsWith(".png")) {
            throw new IllegalArgumentException("Invalid file format. Only JPG, JPEG, and PNG screenshots are allowed.");
        }

        // Validate file size (max 5 MB)
        if (file.getSize() > 5 * 1024 * 1024) {
            throw new IllegalArgumentException("File size exceeds maximum limit of 5 MB");
        }

        Student student = getStudentByEmail(email);
        LocalDate joiningDate = FeeCycleHelper.getTuitionJoiningDate(student);
        LocalDate[] cycle = FeeCycleHelper.calculateFeeCycle(joiningDate, LocalDate.now());
        LocalDate cycleStart = cycle[0];
        LocalDate cycleEnd = cycle[1];

        // Fetch current paid amount in this cycle
        List<Payment> cyclePayments = paymentRepository.findByStudentIdAndFeeCycleStartAndFeeCycleEnd(
                student.getId(), cycleStart, cycleEnd);
        BigDecimal currentPaid = cyclePayments.stream()
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal remainingFee = FeeCycleHelper.ANNUAL_FEE.subtract(currentPaid);
        if (remainingFee.compareTo(BigDecimal.ZERO) < 0) {
            remainingFee = BigDecimal.ZERO;
        }

        if (amount.compareTo(remainingFee) > 0) {
            throw new IllegalArgumentException("Payment amount exceeds the remaining annual fee.");
        }

        // Store proof screenshot
        String proofUrl = fileStorageService.storeFile(file);

        // Generate payment ID
        String paymentIdStr = "PAY" + System.currentTimeMillis();

        Payment payment = Payment.builder()
                .paymentId(paymentIdStr)
                .student(student)
                .feeCycleStart(cycleStart)
                .feeCycleEnd(cycleEnd)
                .amount(amount)
                .paymentProofUrl(proofUrl)
                .paymentDate(LocalDateTime.now())
                .isSeenByTopAdmin(false)
                .build();

        paymentRepository.save(payment);

        eventPublisher.publishToUser(email, "PAYMENT_CREATED", "PAYMENT", payment.getId());
        eventPublisher.publishToUser(email, "FEE_STATUS_UPDATED", "FEE", student.getId());
        eventPublisher.publishToAdmin("PAYMENT_CREATED", "PAYMENT", payment.getId());
        eventPublisher.publishToAdmin("FEE_STATUS_UPDATED", "FEE", student.getId());

        return getStudentFeeSummary(email);
    }

    @Override
    @Transactional(readOnly = true)
    public AdminFeesSummaryResponse getAdminFeesSummary(String filter, String search) {
        LocalDateTime[] range = parseFilterRange(filter);
        LocalDateTime start = range[0];
        LocalDateTime end = range[1];

        List<Payment> payments;
        if (search != null && !search.trim().isEmpty()) {
            payments = paymentRepository.findByPaymentDateBetweenAndSearchQuery(start, end, search.trim());
        } else {
            payments = paymentRepository.findByPaymentDateBetweenOrderByPaymentDateDesc(start, end);
        }

        BigDecimal totalCollected = payments.stream()
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        int paymentCount = payments.size();
        int studentsPaidCount = (int) payments.stream()
                .map(p -> p.getStudent().getId())
                .distinct()
                .count();

        List<PaymentDTO> paymentDTOs = payments.stream().map(this::mapToDTO).collect(Collectors.toList());

        String filterName = filter != null ? filter.toUpperCase() : "TODAY";

        return AdminFeesSummaryResponse.builder()
                .filter(filterName)
                .totalCollected(totalCollected)
                .paymentCount(paymentCount)
                .studentsPaidCount(studentsPaidCount)
                .payments(paymentDTOs)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<PaymentDTO> getAdminFeesPayments(String filter, String search) {
        LocalDateTime[] range = parseFilterRange(filter);
        LocalDateTime start = range[0];
        LocalDateTime end = range[1];

        List<Payment> payments;
        if (search != null && !search.trim().isEmpty()) {
            payments = paymentRepository.findByPaymentDateBetweenAndSearchQuery(start, end, search.trim());
        } else {
            payments = paymentRepository.findByPaymentDateBetweenOrderByPaymentDateDesc(start, end);
        }

        return payments.stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public AdminStudentFeeDetailsResponse getAdminStudentFeeDetails(String studentIdStr) {
        Student student = null;
        try {
            Long id = Long.parseLong(studentIdStr);
            student = studentRepository.findById(id).orElse(null);
        } catch (NumberFormatException ignored) {}

        if (student == null) {
            student = studentRepository.findByStudentCode(studentIdStr)
                    .orElseThrow(() -> new IllegalArgumentException("Student not found with ID/Code: " + studentIdStr));
        }

        LocalDate joiningDate = FeeCycleHelper.getTuitionJoiningDate(student);
        LocalDate[] cycle = FeeCycleHelper.calculateFeeCycle(joiningDate, LocalDate.now());
        LocalDate cycleStart = cycle[0];
        LocalDate cycleEnd = cycle[1];

        List<Payment> cyclePayments = paymentRepository.findByStudentIdAndFeeCycleStartAndFeeCycleEnd(
                student.getId(), cycleStart, cycleEnd);

        BigDecimal paidAmount = cyclePayments.stream()
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal remainingAmount = FeeCycleHelper.ANNUAL_FEE.subtract(paidAmount);
        if (remainingAmount.compareTo(BigDecimal.ZERO) < 0) {
            remainingAmount = BigDecimal.ZERO;
        }

        FeeStatus status;
        if (paidAmount.compareTo(BigDecimal.ZERO) == 0) {
            status = FeeStatus.PENDING;
        } else if (paidAmount.compareTo(FeeCycleHelper.ANNUAL_FEE) < 0) {
            status = FeeStatus.PARTIALLY_PAID;
        } else {
            status = FeeStatus.PAID;
        }

        List<Payment> allPayments = paymentRepository.findByStudentIdOrderByPaymentDateDesc(student.getId());
        List<PaymentDTO> paymentDTOs = allPayments.stream().map(this::mapToDTO).collect(Collectors.toList());

        String studentName = getStudentFullName(student);
        String studentCode = student.getStudentCode() != null ? student.getStudentCode() : "ST" + student.getId();

        return AdminStudentFeeDetailsResponse.builder()
                .studentId(studentCode)
                .dbStudentId(student.getId())
                .studentName(studentName)
                .tuitionJoiningDate(joiningDate)
                .feeCycleStart(cycleStart)
                .feeCycleEnd(cycleEnd)
                .annualFee(FeeCycleHelper.ANNUAL_FEE)
                .paidAmount(paidAmount)
                .remainingAmount(remainingAmount)
                .status(status)
                .payments(paymentDTOs)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public NotificationCountResponse getUnseenNotificationCount() {
        long count = paymentRepository.countByIsSeenByTopAdminFalse();
        return new NotificationCountResponse(count);
    }

    @Override
    @Transactional
    public MessageResponse markNotificationsSeen() {
        List<Payment> unseenPayments = paymentRepository.findByIsSeenByTopAdminFalse();
        LocalDateTime now = LocalDateTime.now();
        for (Payment payment : unseenPayments) {
            payment.setIsSeenByTopAdmin(true);
            payment.setSeenAt(now);
        }
        paymentRepository.saveAll(unseenPayments);
        return new MessageResponse("Marked " + unseenPayments.size() + " payments as seen");
    }

    private LocalDateTime[] parseFilterRange(String filter) {
        LocalDate now = LocalDate.now();
        LocalDateTime start;
        LocalDateTime end;

        if ("week".equalsIgnoreCase(filter) || "this_week".equalsIgnoreCase(filter)) {
            LocalDate monday = now.with(DayOfWeek.MONDAY);
            LocalDate sunday = now.with(DayOfWeek.SUNDAY);
            start = monday.atStartOfDay();
            end = sunday.atTime(23, 59, 59, 999999999);
        } else if ("month".equalsIgnoreCase(filter) || "this_month".equalsIgnoreCase(filter)) {
            LocalDate firstDay = now.with(TemporalAdjusters.firstDayOfMonth());
            LocalDate lastDay = now.with(TemporalAdjusters.lastDayOfMonth());
            start = firstDay.atStartOfDay();
            end = lastDay.atTime(23, 59, 59, 999999999);
        } else {
            // Default to TODAY
            start = now.atStartOfDay();
            end = now.atTime(23, 59, 59, 999999999);
        }

        return new LocalDateTime[]{start, end};
    }

    private String getStudentFullName(Student student) {
        if (student == null) return "";
        String firstLast = ((student.getFirstName() != null ? student.getFirstName() : "") + " " +
                            (student.getLastName() != null ? student.getLastName() : "")).trim();
        if (!firstLast.isEmpty()) {
            return firstLast;
        }
        if (student.getUser() != null && student.getUser().getName() != null) {
            return student.getUser().getName();
        }
        return "";
    }

    private PaymentDTO mapToDTO(Payment p) {
        String studentName = "";
        String studentCode = "";
        Long dbStudentId = null;
        if (p.getStudent() != null) {
            dbStudentId = p.getStudent().getId();
            studentCode = p.getStudent().getStudentCode() != null ? p.getStudent().getStudentCode() : "ST" + dbStudentId;
            studentName = getStudentFullName(p.getStudent());
        }

        return PaymentDTO.builder()
                .id(p.getId())
                .paymentId(p.getPaymentId())
                .dbStudentId(dbStudentId)
                .studentId(studentCode)
                .studentName(studentName)
                .amount(p.getAmount())
                .paymentDate(p.getPaymentDate())
                .paymentDateFormatted(p.getPaymentDate() != null ? p.getPaymentDate().format(DATE_FORMATTER) : "")
                .paymentTimeFormatted(p.getPaymentDate() != null ? p.getPaymentDate().format(TIME_FORMATTER) : "")
                .proofUrl(p.getPaymentProofUrl())
                .feeCycleStart(p.getFeeCycleStart())
                .feeCycleEnd(p.getFeeCycleEnd())
                .isSeenByTopAdmin(p.getIsSeenByTopAdmin())
                .build();
    }
}
