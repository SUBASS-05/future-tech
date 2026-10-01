package com.futuretech.service.impl;

import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.entity.enums.*;
import com.futuretech.repository.*;
import com.futuretech.service.LeaveService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LeaveServiceImpl implements LeaveService {
    private final LeaveRequestRepository leaveRequestRepository;
    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final AttendanceRepository attendanceRepository;

    @Override
    @Transactional
    public MessageResponse applyLeave(String studentEmail, CreateLeaveRequest request) {
        if (request.getStartDate() == null || request.getEndDate() == null) {
            throw new RuntimeException("Start date and end date are required");
        }
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new RuntimeException("End date cannot be before start date");
        }
        if (request.getReason() == null || request.getReason().trim().isEmpty()) {
            throw new RuntimeException("Reason is required");
        }

        User user = userRepository.findByEmail(studentEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("Student not found"));

        LeaveRequest leave = LeaveRequest.builder()
                .student(student)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .reason(request.getReason().trim())
                .status(LeaveStatus.PENDING)
                .build();

        leaveRequestRepository.save(leave);
        return new MessageResponse("Leave request submitted successfully");
    }

    @Override
    public List<LeaveRequestDTO> getMyLeaveRequests(String studentEmail) {
        User user = userRepository.findByEmail(studentEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("Student not found"));

        List<LeaveRequest> list = leaveRequestRepository.findByStudentIdOrderByCreatedAtDesc(student.getId());
        return list.stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    @Override
    public List<LeaveRequestDTO> getAllLeaveRequests(String status) {
        List<LeaveRequest> list;
        if (status != null && !status.trim().isEmpty() && !status.equalsIgnoreCase("ALL")) {
            try {
                LeaveStatus leaveStatus = LeaveStatus.valueOf(status.toUpperCase());
                list = leaveRequestRepository.findByStatusOrderByCreatedAtDesc(leaveStatus);
            } catch (IllegalArgumentException e) {
                list = leaveRequestRepository.findAllByOrderByCreatedAtDesc();
            }
        } else {
            list = leaveRequestRepository.findAllByOrderByCreatedAtDesc();
        }
        return list.stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public MessageResponse reviewLeaveRequest(String adminEmail, Long leaveId, ReviewLeaveRequest request) {
        LeaveRequest leave = leaveRequestRepository.findById(leaveId)
                .orElseThrow(() -> new RuntimeException("Leave request not found"));

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new RuntimeException("Admin not found"));

        LeaveStatus newStatus;
        try {
            newStatus = LeaveStatus.valueOf(request.getStatus().toUpperCase());
        } catch (Exception e) {
            throw new RuntimeException("Invalid leave status");
        }

        leave.setStatus(newStatus);
        leave.setReviewedBy(admin);
        leave.setReviewedAt(LocalDateTime.now());
        leave.setAdminRemarks(request.getAdminRemarks());

        leaveRequestRepository.save(leave);

        // If approved, mark LEAVE status in attendance table for covered dates
        if (newStatus == LeaveStatus.APPROVED) {
            LocalDate curr = leave.getStartDate();
            while (!curr.isAfter(leave.getEndDate())) {
                final LocalDate dateForAtt = curr;
                var existingOpt = attendanceRepository.findByStudentIdAndAttendanceDate(leave.getStudent().getId(), dateForAtt);
                Attendance att = existingOpt.orElseGet(() -> Attendance.builder()
                        .student(leave.getStudent())
                        .attendanceDate(dateForAtt)
                        .build());
                att.setAttendanceDate(curr);
                att.setStatus(AttendanceStatus.LEAVE);
                att.setRemarks("Approved Leave: " + leave.getReason());
                attendanceRepository.save(att);

                curr = curr.plusDays(1);
            }
        }

        return new MessageResponse("Leave request " + newStatus.name().toLowerCase());
    }

    private LeaveRequestDTO mapToDTO(LeaveRequest l) {
        Student s = l.getStudent();
        String studentName = (s.getFirstName() != null ? s.getFirstName() : "") + " " + (s.getLastName() != null ? s.getLastName() : "");
        if (studentName.trim().isEmpty() && s.getUser() != null) {
            studentName = s.getUser().getName();
        }

        String adminName = l.getReviewedBy() != null ? l.getReviewedBy().getName() : null;

        return LeaveRequestDTO.builder()
                .id(l.getId())
                .studentId(s.getId())
                .studentCode(s.getStudentCode())
                .studentName(studentName.trim())
                .startDate(l.getStartDate())
                .endDate(l.getEndDate())
                .reason(l.getReason())
                .status(l.getStatus().name())
                .reviewedByAdminName(adminName)
                .reviewedAt(l.getReviewedAt())
                .adminRemarks(l.getAdminRemarks())
                .createdAt(l.getCreatedAt())
                .build();
    }
}
