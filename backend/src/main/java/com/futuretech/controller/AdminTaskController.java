package com.futuretech.controller;
import com.futuretech.dto.*;
import com.futuretech.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/admin/tasks")
@RequiredArgsConstructor
public class AdminTaskController {
    private final TaskService taskService;
    @PostMapping
    public ResponseEntity<MessageResponse> createTask(Authentication auth, @RequestBody TaskRequest request) {
        return ResponseEntity.ok(taskService.createTask(auth.getName(), request));
    }
}
