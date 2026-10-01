package com.futuretech.controller;

import com.futuretech.dto.StudentAttendanceSummaryResponse;
import com.futuretech.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/student/attendance")
@RequiredArgsConstructor
@PreAuthorize("hasRole('STUDENT')")
public class StudentAttendanceController {
    private final AttendanceService attendanceService;

    @GetMapping
    public ResponseEntity<StudentAttendanceSummaryResponse> getMyAttendance(Authentication auth) {
        return ResponseEntity.ok(attendanceService.getMyAttendanceSummary(auth.getName()));
    }

    @GetMapping("/summary")
    public ResponseEntity<StudentAttendanceSummaryResponse> getMyAttendanceSummary(Authentication auth) {
        return ResponseEntity.ok(attendanceService.getMyAttendanceSummary(auth.getName()));
    }
}
