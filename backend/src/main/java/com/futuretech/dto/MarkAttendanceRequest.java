package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MarkAttendanceRequest {
    private Long studentId;
    private LocalDate attendanceDate;
    private String status;
    private String remarks;
}
