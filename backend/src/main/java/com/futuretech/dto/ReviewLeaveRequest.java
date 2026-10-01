package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReviewLeaveRequest {
    private String status; // APPROVED, REJECTED
    private String adminRemarks;
}
