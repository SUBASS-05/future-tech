package com.futuretech.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class StudentProfileUpdateDTO {
    private String phone;
    private LocalDate dateOfBirth;
    private String educationType;
    private String departmentName;
    private Integer joiningYear;
    private Integer passingYear;
}
