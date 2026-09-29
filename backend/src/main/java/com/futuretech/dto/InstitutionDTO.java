package com.futuretech.dto;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class InstitutionDTO {
    private Long id;
    private String institutionName;
    private String institutionType;
    private String location;
}
