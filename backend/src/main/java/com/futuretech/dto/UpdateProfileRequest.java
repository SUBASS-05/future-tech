package com.futuretech.dto;
import lombok.Data;
import java.time.LocalDate;

@Data
public class UpdateProfileRequest {
    private String firstName;
    private String lastName;
    private LocalDate dateOfBirth;
    private String gender;
    private String phone;
    private String address;
    private String city;
    private String parentName;
    private String parentPhone;
    private String profilePhotoUrl;
    private String educationType;
    private Long institutionId;
    private Long departmentId;
    private String classStandard;
    private String section;
    private String academicYear;
    private Integer joiningYear;
    private Integer passingYear;
}
