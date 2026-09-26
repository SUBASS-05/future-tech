package com.futuretech.controller;
import com.futuretech.dto.*;
import com.futuretech.service.FinanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminFinanceController {
    private final FinanceService financeService;
    @PostMapping("/fees")
    public ResponseEntity<MessageResponse> createFee(@RequestBody FeeRequest request) {
        return ResponseEntity.ok(financeService.createFee(request));
    }
    @PostMapping("/payments")
    public ResponseEntity<MessageResponse> recordPayment(@RequestBody PaymentRequest request) {
        return ResponseEntity.ok(financeService.recordPayment(request));
    }
}
