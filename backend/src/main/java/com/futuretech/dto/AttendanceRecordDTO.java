package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceRecordDTO {
    private Long attendanceId;
    private Long studentId;
    private String studentCode;
    private String studentName;
    private String department;
    private String institution;
    private LocalDate attendanceDate;
    private String status;
    private String remarks;
}
