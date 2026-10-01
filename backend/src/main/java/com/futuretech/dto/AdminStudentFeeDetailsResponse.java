package com.futuretech.dto;

import com.futuretech.entity.enums.FeeStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminStudentFeeDetailsResponse {
    private String studentId;
    private Long dbStudentId;
    private String studentName;
    private LocalDate tuitionJoiningDate;
    private LocalDate feeCycleStart;
    private LocalDate feeCycleEnd;
    private BigDecimal annualFee;
    private BigDecimal paidAmount;
    private BigDecimal remainingAmount;
    private FeeStatus status;
    private List<PaymentDTO> payments;
}
