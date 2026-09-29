package com.futuretech.dto;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class StudentRequestDTO {
    private Long studentId;
    private String fullName;
    private String email;
    private String institutionName;
    private String tuitionJoiningDate;
    private String status;
}
