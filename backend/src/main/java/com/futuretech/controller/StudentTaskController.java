package com.futuretech.controller;

import com.futuretech.dto.*;
import com.futuretech.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/student/tasks")
@RequiredArgsConstructor
public class StudentTaskController {
    private final TaskService taskService;

    // GET /api/student/tasks  →  handled by StudentFeatureController to avoid ambiguous mapping
    // Only the by-ID lookup is unique to this controller
    @GetMapping("/{taskId}")
    public ResponseEntity<StudentTaskResponse> getStudentTaskById(Authentication auth, @PathVariable Long taskId) {
        return ResponseEntity.ok(taskService.getStudentTaskById(auth.getName(), taskId));
    }
}
