package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentTaskProgressDTO {
    private Long studentId;
    private String studentName;
    private String studentRegistrationId;
    private String status;
    private LocalDateTime assignedAt;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private boolean isOverdue;
    private LocalDateTime dueAt;
    private LocalDateTime expiresAt;
}
