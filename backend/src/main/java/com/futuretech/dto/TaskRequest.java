package com.futuretech.dto;
import lombok.Data;
import java.time.LocalDate;
@Data
public class TaskRequest {
    private String title;
    private String description;
    private LocalDate dueDate;
    private String targetType;
    private String academicBatch;
    private Long departmentId;
    private Long institutionId;
}
