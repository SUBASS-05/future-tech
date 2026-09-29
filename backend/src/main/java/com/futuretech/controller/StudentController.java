package com.futuretech.controller;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentProfileDTO;
import com.futuretech.dto.UpdateProfileRequest;
import com.futuretech.dto.InstitutionDTO;
import com.futuretech.dto.DepartmentDTO;
import com.futuretech.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
public class StudentController {
    private final StudentService studentService;

    @GetMapping("/profile")
    public ResponseEntity<StudentProfileDTO> getProfile(Authentication authentication) {
        return ResponseEntity.ok(studentService.getProfile(authentication.getName()));
    }

    @PutMapping("/profile")
    public ResponseEntity<MessageResponse> updateProfile(Authentication authentication, @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(studentService.updateProfile(authentication.getName(), request));
    }
    
    @GetMapping("/institutions")
    public ResponseEntity<List<InstitutionDTO>> getInstitutions() {
        return ResponseEntity.ok(studentService.getInstitutions());
    }

    @GetMapping("/institutions/{institutionId}/departments")
    public ResponseEntity<List<DepartmentDTO>> getDepartments(@PathVariable Long institutionId) {
        return ResponseEntity.ok(studentService.getDepartments(institutionId));
    }

    @PostMapping("/profile/photo")
    public ResponseEntity<MessageResponse> uploadProfilePhoto(Authentication authentication, @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(studentService.uploadProfilePhoto(authentication.getName(), file));
    }

    @DeleteMapping("/profile/photo")
    public ResponseEntity<MessageResponse> removeProfilePhoto(Authentication authentication) {
        return ResponseEntity.ok(studentService.removeProfilePhoto(authentication.getName()));
    }
}
