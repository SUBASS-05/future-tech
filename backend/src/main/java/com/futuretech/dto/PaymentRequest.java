package com.futuretech.dto;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
@Data
public class PaymentRequest {
    private Long feeRecordId;
    private BigDecimal amount;
    private LocalDate paymentDate;
    private String paymentMethod;
    private String remarks;
}
