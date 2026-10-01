package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateLeaveRequest {
    private LocalDate startDate;
    private LocalDate endDate;
    private String reason;
}
