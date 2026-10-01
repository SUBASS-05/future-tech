package com.futuretech.service;

import com.futuretech.dto.*;
import com.futuretech.entity.Attendance;

import java.time.LocalDate;
import java.util.List;

public interface AttendanceService {
    DailyAttendanceResponse getDailyAttendance(LocalDate date);
    MessageResponse markAttendance(MarkAttendanceRequest request);
    MessageResponse bulkMarkAttendance(BulkMarkAttendanceRequest request);
    StudentAttendanceSummaryResponse getStudentAttendanceSummary(Long studentId);
    StudentAttendanceSummaryResponse getMyAttendanceSummary(String studentEmail);
    List<LowAttendanceStudentDTO> getLowAttendanceStudents(double thresholdPercentage);
    List<Attendance> getStudentAttendance(Long studentId);
}
