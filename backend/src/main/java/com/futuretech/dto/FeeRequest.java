package com.futuretech.dto;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
@Data
public class FeeRequest {
    private Long studentId;
    private String feeName;
    private BigDecimal totalAmount;
    private BigDecimal discountAmount;
    private LocalDate dueDate;
}
