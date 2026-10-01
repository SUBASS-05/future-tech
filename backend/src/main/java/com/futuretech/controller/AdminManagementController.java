package com.futuretech.controller;

import com.futuretech.entity.AdminProfile;
import com.futuretech.entity.User;
import com.futuretech.entity.enums.AdminStatus;
import com.futuretech.repository.AdminProfileRepository;
import com.futuretech.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admins/management")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TOP_ADMIN')")
public class AdminManagementController {

    private final AdminProfileRepository adminProfileRepository;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAdminManagementData() {
        List<AdminProfile> all = adminProfileRepository.findAll();

        List<Map<String, Object>> pending = all.stream()
                .filter(a -> a.getStatus() == AdminStatus.PENDING_VERIFICATION)
                .map(this::mapAdminProfile)
                .collect(Collectors.toList());

        List<Map<String, Object>> active = all.stream()
                .filter(a -> a.getStatus() == AdminStatus.ACTIVE)
                .map(this::mapAdminProfile)
                .collect(Collectors.toList());

        List<Map<String, Object>> suspended = all.stream()
                .filter(a -> a.getStatus() == AdminStatus.SUSPENDED)
                .map(this::mapAdminProfile)
                .collect(Collectors.toList());

        List<Map<String, Object>> rejected = all.stream()
                .filter(a -> a.getStatus() == AdminStatus.REJECTED)
                .map(this::mapAdminProfile)
                .collect(Collectors.toList());

        long activeCount = active.size();
        long pendingCount = pending.size();
        long availableSlots = Math.max(0, 9 - (activeCount + pendingCount));

        Map<String, Object> capacity = new HashMap<>();
        capacity.put("activeAdmins", activeCount);
        capacity.put("pendingRequests", pendingCount);
        capacity.put("availableSlots", availableSlots);

        Map<String, Object> response = new HashMap<>();
        response.put("pending", pending);
        response.put("active", active);
        response.put("suspended", suspended);
        response.put("rejected", rejected);
        response.put("capacity", capacity);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<?> approveAdmin(@PathVariable Long id) {
        long activeCount = adminProfileRepository.countByStatusIn(List.of(AdminStatus.ACTIVE));
        if (activeCount >= 9) {
            Map<String, String> err = new HashMap<>();
            err.put("message", "The maximum number of regular Admin accounts has been reached.");
            return ResponseEntity.status(409).body(err);
        }
        AdminProfile admin = adminProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        String currentEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        User verifiedBy = userRepository.findByEmail(currentEmail).orElse(null);

        admin.setStatus(AdminStatus.ACTIVE);
        admin.setAdminId("FTADM" + String.format("%03d", activeCount + 1));
        admin.setJoiningDate(LocalDate.now());
        admin.setVerifiedAt(LocalDateTime.now());
        admin.setVerifiedBy(verifiedBy);
        if (admin.getUser() != null) {
            admin.getUser().setIsActive(true);
            userRepository.save(admin.getUser());
        }
        adminProfileRepository.save(admin);
        Map<String, String> res = new HashMap<>();
        res.put("message", "Admin approved successfully");
        return ResponseEntity.ok(res);
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<?> rejectAdmin(@PathVariable Long id) {
        AdminProfile admin = adminProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        admin.setStatus(AdminStatus.REJECTED);
        adminProfileRepository.save(admin);
        Map<String, String> res = new HashMap<>();
        res.put("message", "Admin rejected");
        return ResponseEntity.ok(res);
    }

    @PostMapping("/{id}/suspend")
    public ResponseEntity<?> suspendAdmin(@PathVariable Long id) {
        AdminProfile admin = adminProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        admin.setStatus(AdminStatus.SUSPENDED);
        if (admin.getUser() != null) {
            admin.getUser().setIsActive(false);
            userRepository.save(admin.getUser());
        }
        adminProfileRepository.save(admin);
        Map<String, String> res = new HashMap<>();
        res.put("message", "Admin suspended");
        return ResponseEntity.ok(res);
    }

    @PostMapping("/{id}/activate")
    public ResponseEntity<?> activateAdmin(@PathVariable Long id) {
        long activeCount = adminProfileRepository.countByStatusIn(List.of(AdminStatus.ACTIVE));
        if (activeCount >= 9) {
            Map<String, String> err = new HashMap<>();
            err.put("message", "The maximum number of regular Admin accounts has been reached.");
            return ResponseEntity.status(409).body(err);
        }
        AdminProfile admin = adminProfileRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        admin.setStatus(AdminStatus.ACTIVE);
        if (admin.getUser() != null) {
            admin.getUser().setIsActive(true);
            userRepository.save(admin.getUser());
        }
        adminProfileRepository.save(admin);
        Map<String, String> res = new HashMap<>();
        res.put("message", "Admin activated");
        return ResponseEntity.ok(res);
    }

    private Map<String, Object> mapAdminProfile(AdminProfile a) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", a.getId());
        map.put("adminId", a.getAdminId());
        map.put("firstName", a.getFirstName() != null ? a.getFirstName() : (a.getUser() != null ? a.getUser().getName() : "Admin"));
        map.put("lastName", a.getLastName() != null ? a.getLastName() : "");
        map.put("email", a.getUser() != null ? a.getUser().getEmail() : "");
        map.put("phone", a.getPhone());
        map.put("joiningDate", a.getJoiningDate() != null ? a.getJoiningDate().toString() : null);
        map.put("status", a.getStatus().name());
        return map;
    }
}
