package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentDTO {
    private Long id;
    private String paymentId;
    private Long dbStudentId;
    private String studentId;
    private String studentName;
    private BigDecimal amount;
    private LocalDateTime paymentDate;
    private String paymentDateFormatted;
    private String paymentTimeFormatted;
    private String proofUrl;
    private LocalDate feeCycleStart;
    private LocalDate feeCycleEnd;
    private Boolean isSeenByTopAdmin;
}
