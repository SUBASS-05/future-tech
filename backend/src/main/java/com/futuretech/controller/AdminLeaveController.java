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
@RequestMapping("/api/admin/leaves")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('TOP_ADMIN', 'ADMIN')")
public class AdminLeaveController {
    private final LeaveService leaveService;

    @GetMapping
    public ResponseEntity<List<LeaveRequestDTO>> getAllLeaveRequests(
            @RequestParam(value = "status", required = false) String status) {
        return ResponseEntity.ok(leaveService.getAllLeaveRequests(status));
    }

    @PostMapping("/{leaveId}/review")
    public ResponseEntity<MessageResponse> reviewLeaveRequest(
            Authentication auth,
            @PathVariable Long leaveId,
            @RequestBody ReviewLeaveRequest request) {
        return ResponseEntity.ok(leaveService.reviewLeaveRequest(auth.getName(), leaveId, request));
    }
}
