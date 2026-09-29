package com.futuretech.dto;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DepartmentDTO {
    private Long id;
    private Long institutionId;
    private String departmentName;
    private String departmentCode;
}
