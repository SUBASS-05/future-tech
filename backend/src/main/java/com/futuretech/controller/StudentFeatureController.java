package com.futuretech.controller;

import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
public class StudentFeatureController {
    private final FinanceService financeService;
    private final AttendanceService attendanceService;
    private final TaskService taskService;

    @GetMapping("/fees")
    public ResponseEntity<StudentFeeSummaryResponse> getFees(Authentication auth) {
        return ResponseEntity.ok(financeService.getStudentFeeSummary(auth.getName()));
    }

    @GetMapping("/fees/payments")
    public ResponseEntity<List<PaymentDTO>> getFeePayments(Authentication auth) {
        return ResponseEntity.ok(financeService.getStudentPayments(auth.getName()));
    }

    @GetMapping("/payments")
    public ResponseEntity<List<PaymentDTO>> getPayments(Authentication auth) {
        return ResponseEntity.ok(financeService.getStudentPayments(auth.getName()));
    }

    @PostMapping(value = "/fees/payments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<StudentFeeSummaryResponse> submitPayment(
            Authentication auth,
            @RequestParam("amount") BigDecimal amount,
            @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(financeService.submitStudentPayment(auth.getName(), amount, file));
    }


    @GetMapping("/tasks")
    public ResponseEntity<List<StudentTaskResponse>> getTasks(Authentication auth) {
        return ResponseEntity.ok(taskService.getStudentTasks(auth.getName()));
    }

    @PutMapping("/tasks/{taskId}/status")
    public ResponseEntity<MessageResponse> updateTask(Authentication auth, @PathVariable Long taskId, @RequestBody TaskStatusUpdateRequest req) {
        return ResponseEntity.ok(taskService.updateTaskStatus(auth.getName(), taskId, req.getStatus()));
    }
}
