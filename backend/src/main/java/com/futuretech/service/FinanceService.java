package com.futuretech.service;

import com.futuretech.dto.*;
import org.springframework.web.multipart.MultipartFile;
import java.math.BigDecimal;
import java.util.List;

public interface FinanceService {
    StudentFeeSummaryResponse getStudentFeeSummary(String email);

    List<PaymentDTO> getStudentPayments(String email);

    StudentFeeSummaryResponse submitStudentPayment(String email, BigDecimal amount, MultipartFile file);

    AdminFeesSummaryResponse getAdminFeesSummary(String filter, String search);

    List<PaymentDTO> getAdminFeesPayments(String filter, String search);

    AdminStudentFeeDetailsResponse getAdminStudentFeeDetails(String studentId);

    NotificationCountResponse getUnseenNotificationCount();

    MessageResponse markNotificationsSeen();
}
