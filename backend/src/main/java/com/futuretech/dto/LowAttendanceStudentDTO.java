package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LowAttendanceStudentDTO {
    private Long studentId;
    private String studentCode;
    private String studentName;
    private String department;
    private String institution;
    private int presentCount;
    private int absentCount;
    private int leaveCount;
    private double attendancePercentage;
}
