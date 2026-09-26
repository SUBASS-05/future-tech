package com.futuretech.controller;
import com.futuretech.dto.*;
import com.futuretech.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/admin/attendance")
@RequiredArgsConstructor
public class AdminAttendanceController {
    private final AttendanceService attendanceService;
    @PostMapping
    public ResponseEntity<MessageResponse> markAttendance(@RequestBody AttendanceRequest request) {
        return ResponseEntity.ok(attendanceService.markAttendance(request));
    }
}
