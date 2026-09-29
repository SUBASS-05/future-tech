package com.futuretech.controller;

import com.futuretech.entity.AdminProfile;
import com.futuretech.entity.User;
import com.futuretech.entity.enums.AdminStatus;
import com.futuretech.repository.AdminProfileRepository;
import com.futuretech.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/top-admin")
@RequiredArgsConstructor
public class TopAdminController {

    private final AdminProfileRepository adminProfileRepository;
    private final UserRepository userRepository;

    @GetMapping("/capacity")
    public ResponseEntity<Map<String, Object>> getCapacity() {
        long activeAdmins = adminProfileRepository.countByStatusIn(List.of(AdminStatus.ACTIVE));
        long pendingAdmins = adminProfileRepository.countByStatusIn(List.of(AdminStatus.PENDING_VERIFICATION));
        long availableSlots = 9 - (activeAdmins + pendingAdmins);
        
        Map<String, Object> response = new HashMap<>();
        response.put("maximumAdmins", 9);
        response.put("activeAdmins", activeAdmins);
        response.put("pendingAdmins", pendingAdmins);
        response.put("availableSlots", availableSlots);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/admin-requests")
    public ResponseEntity<List<AdminProfile>> getAdminRequests() {
        return ResponseEntity.ok(adminProfileRepository.findByStatusIn(List.of(AdminStatus.PENDING_VERIFICATION)));
    }

    @GetMapping("/admins")
    public ResponseEntity<List<AdminProfile>> getAllAdmins() {
        return ResponseEntity.ok(adminProfileRepository.findAll());
    }

    @GetMapping("/admins/{id}")
    public ResponseEntity<AdminProfile> getAdminById(@PathVariable Long id) {
        return ResponseEntity.ok(adminProfileRepository.findById(id).orElseThrow());
    }

    @PatchMapping("/admins/{id}/approve")
    public ResponseEntity<AdminProfile> approveAdmin(@PathVariable Long id) {
        AdminProfile admin = adminProfileRepository.findById(id).orElseThrow();
        String currentEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        User verifiedBy = userRepository.findByEmail(currentEmail).orElseThrow();
        
        admin.setStatus(AdminStatus.ACTIVE);
        long activeCount = adminProfileRepository.countByStatusIn(List.of(AdminStatus.ACTIVE));
        admin.setAdminId("FTADM" + String.format("%03d", activeCount + 1));
        admin.setJoiningDate(LocalDate.now());
        admin.setVerifiedAt(java.time.LocalDateTime.now());
        admin.setVerifiedBy(verifiedBy);
        
        return ResponseEntity.ok(adminProfileRepository.save(admin));
    }

    @PatchMapping("/admins/{id}/reject")
    public ResponseEntity<AdminProfile> rejectAdmin(@PathVariable Long id) {
        AdminProfile admin = adminProfileRepository.findById(id).orElseThrow();
        admin.setStatus(AdminStatus.REJECTED);
        return ResponseEntity.ok(adminProfileRepository.save(admin));
    }

    @PatchMapping("/admins/{id}/suspend")
    public ResponseEntity<AdminProfile> suspendAdmin(@PathVariable Long id) {
        AdminProfile admin = adminProfileRepository.findById(id).orElseThrow();
        admin.setStatus(AdminStatus.SUSPENDED);
        admin.getUser().setIsActive(false);
        userRepository.save(admin.getUser());
        return ResponseEntity.ok(adminProfileRepository.save(admin));
    }

    @PatchMapping("/admins/{id}/activate")
    public ResponseEntity<AdminProfile> activateAdmin(@PathVariable Long id) {
        AdminProfile admin = adminProfileRepository.findById(id).orElseThrow();
        admin.setStatus(AdminStatus.ACTIVE);
        admin.getUser().setIsActive(true);
        userRepository.save(admin.getUser());
        return ResponseEntity.ok(adminProfileRepository.save(admin));
    }
}
