package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BulkMarkAttendanceRequest {
    private LocalDate attendanceDate;
    private String status;
    private List<Long> studentIds;
    private String remarks;
}
