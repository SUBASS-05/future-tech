package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminProfileResponse {
    private Long id;
    private String adminId;
    private String firstName;
    private String lastName;
    private String email;
    private String role;
    private LocalDate dateOfBirth;
    private String gender;
    private String phone;
    private String address;
    private String city;
    private String state;
    private String pincode;
    private String qualification;
    private String highestQualification;
    private String institution;
    private String department;
    private String designation;
    private LocalDate joiningDate;
    private String profilePhotoUrl;
    private String status;
    private Boolean profileCompleted;
    private List<String> missingFields;
}
