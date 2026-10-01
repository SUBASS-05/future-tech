package com.futuretech.controller;

import com.futuretech.dto.*;
import com.futuretech.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/admin/attendance")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('TOP_ADMIN', 'ADMIN')")
public class AdminAttendanceController {
    private final AttendanceService attendanceService;

    @GetMapping
    public ResponseEntity<DailyAttendanceResponse> getDailyAttendance(
            @RequestParam(value = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        if (date == null) date = LocalDate.now();
        return ResponseEntity.ok(attendanceService.getDailyAttendance(date));
    }

    @PostMapping
    public ResponseEntity<MessageResponse> markAttendance(@RequestBody MarkAttendanceRequest request) {
        return ResponseEntity.ok(attendanceService.markAttendance(request));
    }

    @PostMapping("/bulk")
    public ResponseEntity<MessageResponse> bulkMarkAttendance(@RequestBody BulkMarkAttendanceRequest request) {
        return ResponseEntity.ok(attendanceService.bulkMarkAttendance(request));
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<StudentAttendanceSummaryResponse> getStudentAttendanceSummary(@PathVariable Long studentId) {
        return ResponseEntity.ok(attendanceService.getStudentAttendanceSummary(studentId));
    }

    @GetMapping("/reports/low-attendance")
    public ResponseEntity<List<LowAttendanceStudentDTO>> getLowAttendanceStudents(
            @RequestParam(value = "threshold", defaultValue = "75.0") double threshold) {
        return ResponseEntity.ok(attendanceService.getLowAttendanceStudents(threshold));
    }
}
