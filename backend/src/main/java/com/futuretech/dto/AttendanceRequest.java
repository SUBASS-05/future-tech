package com.futuretech.dto;
import lombok.Data;
import java.time.LocalDate;
@Data
public class AttendanceRequest {
    private Long studentId;
    private LocalDate attendanceDate;
    private String status;
    private String remarks;
}
