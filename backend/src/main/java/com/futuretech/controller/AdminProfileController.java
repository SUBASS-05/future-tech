package com.futuretech.controller;

import com.futuretech.entity.AdminProfile;
import com.futuretech.entity.User;
import com.futuretech.repository.AdminProfileRepository;
import com.futuretech.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/profile")
@RequiredArgsConstructor
public class AdminProfileController {

    private final AdminProfileRepository adminProfileRepository;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getMyProfile() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email).orElseThrow();
        
        Map<String, Object> response = new HashMap<>();
        
        if ("TOP_ADMIN".equals(user.getUserType().name())) {
            response.put("profile", user);
            response.put("profileCompleted", true);
            response.put("missingFields", new ArrayList<>());
            return ResponseEntity.ok(response);
        }
        
        AdminProfile profile = adminProfileRepository.findByUserId(user.getId()).orElseThrow();
        
        List<String> missingFields = new ArrayList<>();
        if (profile.getFirstName() == null || profile.getFirstName().isEmpty()) missingFields.add("firstName");
        if (profile.getLastName() == null || profile.getLastName().isEmpty()) missingFields.add("lastName");
        if (profile.getDateOfBirth() == null) missingFields.add("dateOfBirth");
        if (profile.getGender() == null || profile.getGender().isEmpty()) missingFields.add("gender");
        if (profile.getPhone() == null || profile.getPhone().isEmpty()) missingFields.add("phone");
        if (profile.getAddress() == null || profile.getAddress().isEmpty()) missingFields.add("address");
        if (profile.getCity() == null || profile.getCity().isEmpty()) missingFields.add("city");
        if (profile.getState() == null || profile.getState().isEmpty()) missingFields.add("state");
        if (profile.getPincode() == null || profile.getPincode().isEmpty()) missingFields.add("pincode");
        if (profile.getQualification() == null || profile.getQualification().isEmpty()) missingFields.add("qualification");
        if (profile.getInstitution() == null || profile.getInstitution().isEmpty()) missingFields.add("institution");
        if (profile.getDepartment() == null || profile.getDepartment().isEmpty()) missingFields.add("department");
        if (profile.getDesignation() == null || profile.getDesignation().isEmpty()) missingFields.add("designation");
        
        boolean completed = missingFields.isEmpty();
        if (profile.getProfileCompleted() != completed) {
            profile.setProfileCompleted(completed);
            adminProfileRepository.save(profile);
        }
        
        response.put("profile", profile);
        response.put("profileCompleted", completed);
        response.put("missingFields", missingFields);
        
        return ResponseEntity.ok(response);
    }

    @PutMapping
    public ResponseEntity<AdminProfile> updateMyProfile(@RequestBody AdminProfile updatedProfile) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email).orElseThrow();
        
        if ("TOP_ADMIN".equals(user.getUserType().name())) {
            throw new RuntimeException("Top Admin profile update not supported here.");
        }
        
        AdminProfile profile = adminProfileRepository.findByUserId(user.getId()).orElseThrow();
        
        // Update fields
        if (updatedProfile.getFirstName() != null) profile.setFirstName(updatedProfile.getFirstName());
        if (updatedProfile.getLastName() != null) profile.setLastName(updatedProfile.getLastName());
        if (updatedProfile.getDateOfBirth() != null) profile.setDateOfBirth(updatedProfile.getDateOfBirth());
        if (updatedProfile.getGender() != null) profile.setGender(updatedProfile.getGender());
        if (updatedProfile.getPhone() != null) profile.setPhone(updatedProfile.getPhone());
        if (updatedProfile.getAddress() != null) profile.setAddress(updatedProfile.getAddress());
        if (updatedProfile.getCity() != null) profile.setCity(updatedProfile.getCity());
        if (updatedProfile.getState() != null) profile.setState(updatedProfile.getState());
        if (updatedProfile.getPincode() != null) profile.setPincode(updatedProfile.getPincode());
        if (updatedProfile.getQualification() != null) profile.setQualification(updatedProfile.getQualification());
        if (updatedProfile.getInstitution() != null) profile.setInstitution(updatedProfile.getInstitution());
        if (updatedProfile.getDepartment() != null) profile.setDepartment(updatedProfile.getDepartment());
        if (updatedProfile.getDesignation() != null) profile.setDesignation(updatedProfile.getDesignation());
        
        return ResponseEntity.ok(adminProfileRepository.save(profile));
    }
}
