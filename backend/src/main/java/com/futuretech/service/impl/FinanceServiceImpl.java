package com.futuretech.service.impl;
import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.entity.enums.*;
import com.futuretech.repository.*;
import com.futuretech.service.FinanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
@Service
@RequiredArgsConstructor
public class FinanceServiceImpl implements FinanceService {
    private final FeeRecordRepository feeRecordRepository;
    private final PaymentRepository paymentRepository;
    private final StudentRepository studentRepository;

    @Override
    @Transactional
    public MessageResponse createFee(FeeRequest request) {
        Student student = studentRepository.findById(request.getStudentId()).orElseThrow();
        BigDecimal finalAmount = request.getTotalAmount().subtract(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO);
        FeeRecord fee = FeeRecord.builder()
            .student(student)
            .feeName(request.getFeeName())
            .totalAmount(request.getTotalAmount())
            .discountAmount(request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO)
            .finalAmount(finalAmount)
            .dueDate(request.getDueDate())
            .status(FeeStatus.PENDING)
            .build();
        feeRecordRepository.save(fee);
        return new MessageResponse("Fee created");
    }

    @Override
    @Transactional
    public MessageResponse recordPayment(PaymentRequest request) {
        FeeRecord fee = feeRecordRepository.findById(request.getFeeRecordId()).orElseThrow();
        Payment payment = Payment.builder()
            .feeRecord(fee)
            .student(fee.getStudent())
            .amount(request.getAmount())
            .paymentDate(request.getPaymentDate())
            .paymentMethod(PaymentMethod.valueOf(request.getPaymentMethod()))
            .receiptNumber("REC-" + UUID.randomUUID().toString().substring(0,6).toUpperCase())
            .remarks(request.getRemarks())
            .build();
        paymentRepository.save(payment);
        
        List<Payment> allPayments = paymentRepository.findByStudentId(fee.getStudent().getId());
        BigDecimal totalPaid = allPayments.stream().filter(p -> p.getFeeRecord().getId().equals(fee.getId())).map(Payment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        if (totalPaid.compareTo(fee.getFinalAmount()) >= 0) {
            fee.setStatus(FeeStatus.PAID);
        } else if (totalPaid.compareTo(BigDecimal.ZERO) > 0) {
            fee.setStatus(FeeStatus.PARTIALLY_PAID);
        }
        feeRecordRepository.save(fee);
        return new MessageResponse("Payment recorded successfully");
    }

    @Override
    public List<FeeRecord> getStudentFees(Long studentId) {
        return feeRecordRepository.findByStudentId(studentId);
    }

    @Override
    public List<Payment> getStudentPayments(Long studentId) {
        return paymentRepository.findByStudentId(studentId);
    }
}
