package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskProgressResponse {
    private Long taskId;
    private String title;
    
    private int totalAssigned;
    private int completed;
    private int inProgress;
    private int pending;
    private int overdue;
    private double completionPercentage;
    private int expiredAssignments;
    private double completionRate;
    
    private List<StudentTaskProgressDTO> students;
}
