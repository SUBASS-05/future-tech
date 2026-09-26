package com.futuretech.service;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentProfileDTO;
import com.futuretech.dto.UpdateProfileRequest;

public interface StudentService {
    StudentProfileDTO getProfile(String email);
    MessageResponse updateProfile(String email, UpdateProfileRequest request);
}
