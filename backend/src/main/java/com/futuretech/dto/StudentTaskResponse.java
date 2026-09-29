package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentTaskResponse {
    private Long assignmentId;
    private Long taskId;
    private String title;
    private String description;
    private String priority;
    private LocalDate dueDate;
    private LocalTime dueTime;
    private Integer estimatedMinutes;
    private String status;
    private LocalDateTime assignedAt;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private boolean isOverdue;
    private LocalDateTime dueAt;
    private LocalDateTime expiresAt;
    private boolean canComplete;
}
