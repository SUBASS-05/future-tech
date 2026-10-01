package com.futuretech.controller;

import com.futuretech.dto.*;
import com.futuretech.service.FinanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/fees")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TOP_ADMIN')")
public class TopAdminFeeController {
    private final FinanceService financeService;

    @GetMapping("/summary")
    public ResponseEntity<AdminFeesSummaryResponse> getFeesSummary(
            @RequestParam(value = "filter", defaultValue = "today") String filter,
            @RequestParam(value = "search", required = false) String search) {
        return ResponseEntity.ok(financeService.getAdminFeesSummary(filter, search));
    }

    @GetMapping("/payments")
    public ResponseEntity<List<PaymentDTO>> getFeesPayments(
            @RequestParam(value = "filter", defaultValue = "today") String filter,
            @RequestParam(value = "search", required = false) String search) {
        return ResponseEntity.ok(financeService.getAdminFeesPayments(filter, search));
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<AdminStudentFeeDetailsResponse> getStudentFeeDetails(
            @PathVariable("studentId") String studentId) {
        return ResponseEntity.ok(financeService.getAdminStudentFeeDetails(studentId));
    }

    @GetMapping("/notifications/count")
    public ResponseEntity<NotificationCountResponse> getUnseenCount() {
        return ResponseEntity.ok(financeService.getUnseenNotificationCount());
    }

    @PatchMapping("/notifications/mark-seen")
    public ResponseEntity<MessageResponse> markSeen() {
        return ResponseEntity.ok(financeService.markNotificationsSeen());
    }
}
