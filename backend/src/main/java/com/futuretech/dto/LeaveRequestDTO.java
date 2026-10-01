package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeaveRequestDTO {
    private Long id;
    private Long studentId;
    private String studentCode;
    private String studentName;
    private LocalDate startDate;
    private LocalDate endDate;
    private String reason;
    private String status;
    private String reviewedByAdminName;
    private LocalDateTime reviewedAt;
    private String adminRemarks;
    private LocalDateTime createdAt;
}
