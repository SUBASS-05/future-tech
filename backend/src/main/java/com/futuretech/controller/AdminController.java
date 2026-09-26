package com.futuretech.controller;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentRequestDTO;
import com.futuretech.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {
    private final AdminService adminService;

    @GetMapping("/student-requests")
    public ResponseEntity<List<StudentRequestDTO>> getPendingRequests() {
        return ResponseEntity.ok(adminService.getPendingRequests());
    }

    @PostMapping("/student-requests/{id}/approve")
    public ResponseEntity<MessageResponse> approveStudent(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.approveStudent(id));
    }

    @PostMapping("/student-requests/{id}/reject")
    public ResponseEntity<MessageResponse> rejectStudent(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.rejectStudent(id));
    }
}
