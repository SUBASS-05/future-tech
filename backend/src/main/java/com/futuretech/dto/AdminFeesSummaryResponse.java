package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminFeesSummaryResponse {
    private String filter;
    private BigDecimal totalCollected;
    private int paymentCount;
    private int studentsPaidCount;
    private List<PaymentDTO> payments;
}
