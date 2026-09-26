package com.futuretech.service;
import com.futuretech.dto.*;
import com.futuretech.entity.FeeRecord;
import com.futuretech.entity.Payment;
import java.util.List;
public interface FinanceService {
    MessageResponse createFee(FeeRequest request);
    MessageResponse recordPayment(PaymentRequest request);
    List<FeeRecord> getStudentFees(Long studentId);
    List<Payment> getStudentPayments(Long studentId);
}
