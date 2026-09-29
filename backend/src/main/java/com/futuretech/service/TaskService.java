package com.futuretech.service;

import com.futuretech.dto.*;

import java.util.List;

public interface TaskService {
    // Admin operations
    MessageResponse createTask(String adminEmail, TaskRequest request);
    List<TaskResponse> getAllTasks(String adminEmail);
    List<TaskResponse> getTaskHistory(String adminEmail);
    TaskResponse getTaskById(String adminEmail, Long taskId);
    MessageResponse updateTask(String adminEmail, Long taskId, TaskRequest request);
    MessageResponse deleteTask(String adminEmail, Long taskId);
    MessageResponse assignStudents(String adminEmail, Long taskId, AssignStudentsRequest request);
    MessageResponse removeAssignment(String adminEmail, Long taskId, Long studentId);
    TaskProgressResponse getTaskProgress(String adminEmail, Long taskId);
    
    // Student operations
    List<StudentTaskResponse> getStudentTasks(String studentEmail);
    StudentTaskResponse getStudentTaskById(String studentEmail, Long taskId);
    MessageResponse updateTaskStatus(String studentEmail, Long taskId, String status);
}
