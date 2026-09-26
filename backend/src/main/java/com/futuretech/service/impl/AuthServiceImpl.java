package com.futuretech.service.impl;
import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.entity.enums.*;
import com.futuretech.repository.*;
import com.futuretech.security.JwtUtil;
import com.futuretech.service.AuthService;
import com.futuretech.service.EmailService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final InstitutionRepository institutionRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final UserDetailsService userDetailsService;
    private final EmailService emailService;

    @Override
    @Transactional
    public MessageResponse registerStudent(RegisterRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email is already registered.");
        }

        User user = User.builder()
                .name(request.getFullName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .userType(UserType.STUDENT)
                .isActive(true)
                .build();
        user = userRepository.save(user);

        Institution tempInstitution = new Institution();
        tempInstitution.setInstitutionName(request.getInstitutionName());
        tempInstitution.setInstitutionType(InstitutionType.COLLEGE); // Default to college for now
        tempInstitution = institutionRepository.save(tempInstitution);

        Student student = Student.builder()
                .user(user)
                .studentCode("FT-" + UUID.randomUUID().toString().substring(0,8).toUpperCase())
                .firstName(request.getFullName())
                .institution(tempInstitution)
                .status(StudentStatus.PENDING_APPROVAL)
                .profileStatus(ProfileStatus.INCOMPLETE)
                .build();
        studentRepository.save(student);

        emailService.sendRegistrationNotificationToAdmin(student);

        return new MessageResponse("Registration Successful. Please wait for Admin approval.");
    }

    @Override
    public AuthResponse login(AuthRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
        User user = userRepository.findByEmail(request.getEmail()).orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getUserType() == UserType.STUDENT) {
            Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student profile not found"));
            if (student.getStatus() != StudentStatus.APPROVED && student.getStatus() != StudentStatus.ACTIVE) {
                throw new RuntimeException("Account is not approved yet. Status: " + student.getStatus());
            }
        }

        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return new AuthResponse(token, user.getUserType().name(), "Login successful");
    }
}
