package com.futuretech.controller;

import com.futuretech.dto.*;
import com.futuretech.service.LeaveService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/student/leaves")
@RequiredArgsConstructor
@PreAuthorize("hasRole('STUDENT')")
public class StudentLeaveController {
    private final LeaveService leaveService;

    @PostMapping
    public ResponseEntity<MessageResponse> applyLeave(Authentication auth, @RequestBody CreateLeaveRequest request) {
        return ResponseEntity.ok(leaveService.applyLeave(auth.getName(), request));
    }

    @GetMapping
    public ResponseEntity<List<LeaveRequestDTO>> getMyLeaveRequests(Authentication auth) {
        return ResponseEntity.ok(leaveService.getMyLeaveRequests(auth.getName()));
    }
}
