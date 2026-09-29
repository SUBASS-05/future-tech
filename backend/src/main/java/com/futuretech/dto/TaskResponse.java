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
public class TaskResponse {
    private Long id;
    private String title;
    private String description;
    private String priority;
    private LocalDate dueDate;
    private LocalTime dueTime;
    private LocalDateTime dueAt;
    private Integer estimatedMinutes;
    private LocalDateTime createdAt;
    private Boolean isActive;
    
    private int assignedCount;
    private int completedCount;
}
