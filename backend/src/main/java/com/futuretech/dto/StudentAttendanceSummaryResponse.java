package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudentAttendanceSummaryResponse {
    private Long studentId;
    private String studentCode;
    private String studentName;
    private String department;
    private String institution;
    private int totalEvaluatedDays;
    private int presentCount;
    private int absentCount;
    private int leaveCount;
    private int notMarkedCount;
    private double attendancePercentage;
    private List<AttendanceRecordDTO> history;
    private Map<String, Object> monthlyStats;
}
