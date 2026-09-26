package com.futuretech.dto;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class StudentProfileDTO {
    private String studentCode;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private LocalDate dateOfBirth;
    private String gender;
    private String address;
    private String city;
    private String educationType;
    private String institutionName;
    private String departmentName;
    private String classStandard;
    private String section;
    private String academicYear;
    private Integer joiningYear;
    private Integer passingYear;
    private String academicBatch;
    private String parentName;
    private String parentPhone;
    private String profilePhotoUrl;
    private String profileStatus;
    private String status;
}
