package com.futuretech.controller;

import com.futuretech.dto.AdminProfileResponse;
import com.futuretech.dto.AdminProfileUpdateDTO;
import com.futuretech.dto.MessageResponse;
import com.futuretech.entity.AdminProfile;
import com.futuretech.entity.User;
import com.futuretech.entity.enums.AdminStatus;
import com.futuretech.entity.enums.UserType;
import com.futuretech.repository.AdminProfileRepository;
import com.futuretech.repository.UserRepository;
import com.futuretech.service.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/admin/profile")
@RequiredArgsConstructor
public class AdminProfileController {

    private final AdminProfileRepository adminProfileRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    private static final List<String> ALLOWED_GENDERS = Arrays.asList("MALE", "FEMALE", "OTHER", "PREFER_NOT_TO_SAY");

    @GetMapping
    public ResponseEntity<AdminProfileResponse> getMyProfile() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        AdminProfile profile = getOrCreateAdminProfile(user);

        return ResponseEntity.ok(buildAdminProfileResponse(user, profile));
    }

    @PutMapping
    public ResponseEntity<AdminProfileResponse> updateMyProfile(@RequestBody AdminProfileUpdateDTO request) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        AdminProfile profile = getOrCreateAdminProfile(user);

        // Validation: Date of Birth
        if (request.getDateOfBirth() != null) {
            if (request.getDateOfBirth().isAfter(LocalDate.now())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Date of birth cannot be in the future.");
            }
            profile.setDateOfBirth(request.getDateOfBirth());
        }

        // Validation: Gender
        if (request.getGender() != null && !request.getGender().trim().isEmpty()) {
            String genderUpper = request.getGender().trim().toUpperCase();
            if (!ALLOWED_GENDERS.contains(genderUpper)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid gender choice. Allowed: Male, Female, Other, Prefer not to say.");
            }
            profile.setGender(genderUpper);
        }

        // Validation: Phone (10 digits for India)
        if (request.getPhone() != null && !request.getPhone().trim().isEmpty()) {
            String phoneClean = request.getPhone().trim();
            if (!phoneClean.matches("^[6-9]\\d{9}$")) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid phone number. Must be a valid 10-digit Indian phone number starting with 6-9.");
            }
            profile.setPhone(phoneClean);
        }

        // Validation: Pincode (6 digits for India)
        if (request.getPincode() != null && !request.getPincode().trim().isEmpty()) {
            String pincodeClean = request.getPincode().trim();
            if (!pincodeClean.matches("^\\d{6}$")) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid pincode. Must be a 6-digit Indian PIN code.");
            }
            profile.setPincode(pincodeClean);
        }

        // Update editable fields
        if (request.getFirstName() != null && !request.getFirstName().trim().isEmpty()) {
            profile.setFirstName(request.getFirstName().trim());
        }
        if (request.getLastName() != null && !request.getLastName().trim().isEmpty()) {
            profile.setLastName(request.getLastName().trim());
        }
        if (request.getAddress() != null && !request.getAddress().trim().isEmpty()) {
            profile.setAddress(request.getAddress().trim());
        }
        if (request.getCity() != null && !request.getCity().trim().isEmpty()) {
            profile.setCity(request.getCity().trim());
        }
        if (request.getState() != null && !request.getState().trim().isEmpty()) {
            profile.setState(request.getState().trim());
        }

        String qual = request.getHighestQualification() != null ? request.getHighestQualification() : request.getQualification();
        if (qual != null && !qual.trim().isEmpty()) {
            profile.setQualification(qual.trim());
        }

        if (request.getInstitution() != null && !request.getInstitution().trim().isEmpty()) {
            profile.setInstitution(request.getInstitution().trim());
        }
        if (request.getDepartment() != null && !request.getDepartment().trim().isEmpty()) {
            profile.setDepartment(request.getDepartment().trim());
        }
        if (request.getDesignation() != null && !request.getDesignation().trim().isEmpty()) {
            profile.setDesignation(request.getDesignation().trim());
        }

        // Update name in user entity if firstName or lastName updated
        if (profile.getFirstName() != null && profile.getLastName() != null) {
            user.setName(profile.getFirstName() + " " + profile.getLastName());
            userRepository.save(user);
        }

        AdminProfile savedProfile = adminProfileRepository.save(profile);

        return ResponseEntity.ok(buildAdminProfileResponse(user, savedProfile));
    }

    @PostMapping("/photo")
    public ResponseEntity<AdminProfileResponse> uploadProfilePhoto(@RequestParam("file") MultipartFile file) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        if (file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is empty.");
        }

        // Validate image format (Allow any image format from gallery / screenshot)
        String contentType = file.getContentType();
        String originalFilename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";

        boolean isImage = (contentType != null && contentType.toLowerCase().startsWith("image/"))
                || originalFilename.endsWith(".jpg")
                || originalFilename.endsWith(".jpeg")
                || originalFilename.endsWith(".png")
                || originalFilename.endsWith(".webp")
                || originalFilename.endsWith(".heic")
                || originalFilename.endsWith(".heif")
                || originalFilename.endsWith(".bmp")
                || originalFilename.endsWith(".gif");

        if (!isImage) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file format. Please upload an image file.");
        }

        // Validate max size 5 MB
        if (file.getSize() > 5 * 1024 * 1024) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File size exceeds 5 MB limit.");
        }

        AdminProfile profile = getOrCreateAdminProfile(user);
        String oldPhotoUrl = profile.getProfilePhotoUrl();

        String newPhotoUrl = fileStorageService.storeFile(file);
        profile.setProfilePhotoUrl(newPhotoUrl);
        AdminProfile saved = adminProfileRepository.save(profile);

        if (oldPhotoUrl != null && !oldPhotoUrl.isEmpty()) {
            try {
                fileStorageService.deleteFile(oldPhotoUrl);
            } catch (Exception ignored) {}
        }

        return ResponseEntity.ok(buildAdminProfileResponse(user, saved));
    }

    @DeleteMapping("/photo")
    public ResponseEntity<AdminProfileResponse> deleteProfilePhoto() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        AdminProfile profile = getOrCreateAdminProfile(user);
        String oldPhotoUrl = profile.getProfilePhotoUrl();

        if (oldPhotoUrl != null && !oldPhotoUrl.isEmpty()) {
            try {
                fileStorageService.deleteFile(oldPhotoUrl);
            } catch (Exception ignored) {}
        }

        profile.setProfilePhotoUrl(null);
        AdminProfile saved = adminProfileRepository.save(profile);

        return ResponseEntity.ok(buildAdminProfileResponse(user, saved));
    }

    private AdminProfile getOrCreateAdminProfile(User user) {
        return adminProfileRepository.findByUserId(user.getId()).orElseGet(() -> {
            String[] nameParts = user.getName() != null ? user.getName().split(" ", 2) : new String[]{"Admin", "User"};
            String firstName = nameParts.length > 0 ? nameParts[0] : "Admin";
            String lastName = nameParts.length > 1 ? nameParts[1] : "User";

            AdminProfile newProfile = AdminProfile.builder()
                    .user(user)
                    .adminId(user.getUserType() == UserType.TOP_ADMIN ? "FTADM001" : ("FTADM00" + user.getId()))
                    .firstName(firstName)
                    .lastName(lastName)
                    .joiningDate(LocalDate.now())
                    .status(AdminStatus.ACTIVE)
                    .profileCompleted(false)
                    .build();
            return adminProfileRepository.save(newProfile);
        });
    }

    private AdminProfileResponse buildAdminProfileResponse(User user, AdminProfile profile) {
        List<String> missingFields = new ArrayList<>();

        if (profile.getFirstName() == null || profile.getFirstName().trim().isEmpty()) missingFields.add("firstName");
        if (profile.getLastName() == null || profile.getLastName().trim().isEmpty()) missingFields.add("lastName");
        if (profile.getDateOfBirth() == null) missingFields.add("dateOfBirth");
        if (profile.getGender() == null || profile.getGender().trim().isEmpty()) missingFields.add("gender");
        
        if (profile.getPhone() == null || profile.getPhone().trim().isEmpty() || !profile.getPhone().trim().matches("^[6-9]\\d{9}$")) {
            missingFields.add("phone");
        }
        
        if (profile.getAddress() == null || profile.getAddress().trim().isEmpty()) missingFields.add("address");
        if (profile.getCity() == null || profile.getCity().trim().isEmpty()) missingFields.add("city");
        if (profile.getState() == null || profile.getState().trim().isEmpty()) missingFields.add("state");
        
        if (profile.getPincode() == null || profile.getPincode().trim().isEmpty() || !profile.getPincode().trim().matches("^\\d{6}$")) {
            missingFields.add("pincode");
        }

        if (profile.getQualification() == null || profile.getQualification().trim().isEmpty()) missingFields.add("highestQualification");
        if (profile.getInstitution() == null || profile.getInstitution().trim().isEmpty()) missingFields.add("institution");
        if (profile.getDepartment() == null || profile.getDepartment().trim().isEmpty()) missingFields.add("department");
        if (profile.getDesignation() == null || profile.getDesignation().trim().isEmpty()) missingFields.add("designation");

        boolean completed = missingFields.isEmpty();
        if (profile.getProfileCompleted() != completed) {
            profile.setProfileCompleted(completed);
            adminProfileRepository.save(profile);
        }

        String displayAdminId = profile.getAdminId() != null ? profile.getAdminId() : ("FTADM00" + user.getId());
        LocalDate joiningDate = profile.getJoiningDate() != null ? profile.getJoiningDate() : (profile.getCreatedAt() != null ? profile.getCreatedAt().toLocalDate() : LocalDate.now());

        return AdminProfileResponse.builder()
                .id(profile.getId())
                .adminId(displayAdminId)
                .firstName(profile.getFirstName())
                .lastName(profile.getLastName())
                .email(user.getEmail())
                .role(user.getUserType().name())
                .dateOfBirth(profile.getDateOfBirth())
                .gender(profile.getGender())
                .phone(profile.getPhone())
                .address(profile.getAddress())
                .city(profile.getCity())
                .state(profile.getState())
                .pincode(profile.getPincode())
                .qualification(profile.getQualification())
                .highestQualification(profile.getQualification())
                .institution(profile.getInstitution())
                .department(profile.getDepartment())
                .designation(profile.getDesignation())
                .joiningDate(joiningDate)
                .profilePhotoUrl(profile.getProfilePhotoUrl())
                .status(profile.getStatus() != null ? profile.getStatus().name() : "ACTIVE")
                .profileCompleted(completed)
                .missingFields(missingFields)
                .build();
    }
}
