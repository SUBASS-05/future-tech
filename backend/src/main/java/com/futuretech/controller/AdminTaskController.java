package com.futuretech.controller;

import com.futuretech.dto.*;
import com.futuretech.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/tasks")
@RequiredArgsConstructor
public class AdminTaskController {
    private final TaskService taskService;

    @PostMapping
    public ResponseEntity<MessageResponse> createTask(Authentication auth, @RequestBody TaskRequest request) {
        return ResponseEntity.ok(taskService.createTask(auth.getName(), request));
    }

    @GetMapping
    public ResponseEntity<List<TaskResponse>> getAllTasks(Authentication auth) {
        return ResponseEntity.ok(taskService.getAllTasks(auth.getName()));
    }

    @GetMapping("/history")
    public ResponseEntity<List<TaskResponse>> getTaskHistory(Authentication auth) {
        return ResponseEntity.ok(taskService.getTaskHistory(auth.getName()));
    }

    @GetMapping("/{taskId}")
    public ResponseEntity<TaskResponse> getTaskById(Authentication auth, @PathVariable Long taskId) {
        return ResponseEntity.ok(taskService.getTaskById(auth.getName(), taskId));
    }

    @PutMapping("/{taskId}")
    public ResponseEntity<MessageResponse> updateTask(Authentication auth, @PathVariable Long taskId, @RequestBody TaskRequest request) {
        return ResponseEntity.ok(taskService.updateTask(auth.getName(), taskId, request));
    }

    @DeleteMapping("/{taskId}")
    public ResponseEntity<MessageResponse> deleteTask(Authentication auth, @PathVariable Long taskId) {
        return ResponseEntity.ok(taskService.deleteTask(auth.getName(), taskId));
    }

    @PostMapping("/{taskId}/assignments")
    public ResponseEntity<MessageResponse> assignStudents(Authentication auth, @PathVariable Long taskId, @RequestBody AssignStudentsRequest request) {
        return ResponseEntity.ok(taskService.assignStudents(auth.getName(), taskId, request));
    }

    @DeleteMapping("/{taskId}/assignments/{studentId}")
    public ResponseEntity<MessageResponse> removeAssignment(Authentication auth, @PathVariable Long taskId, @PathVariable Long studentId) {
        return ResponseEntity.ok(taskService.removeAssignment(auth.getName(), taskId, studentId));
    }

    @GetMapping("/{taskId}/progress")
    public ResponseEntity<TaskProgressResponse> getTaskProgress(Authentication auth, @PathVariable Long taskId) {
        return ResponseEntity.ok(taskService.getTaskProgress(auth.getName(), taskId));
    }
}
