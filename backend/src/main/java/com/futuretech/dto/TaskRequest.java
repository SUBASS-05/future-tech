package com.futuretech.dto;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class TaskRequest {
    private String title;
    private String description;
    private String priority;
    private LocalDateTime dueAt; // mandatory - must not be null
    private Integer estimatedMinutes;
    private List<Long> studentIds;
}
