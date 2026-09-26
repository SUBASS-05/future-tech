package com.futuretech.controller;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentProfileDTO;
import com.futuretech.dto.UpdateProfileRequest;
import com.futuretech.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

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
}
