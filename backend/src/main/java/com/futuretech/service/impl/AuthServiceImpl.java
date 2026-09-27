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
        
        boolean isAdmin = "ADMIN".equalsIgnoreCase(request.getRole());

        User user = User.builder()
                .name(request.getFullName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .userType(isAdmin ? UserType.ADMIN : UserType.STUDENT)
                .isActive(true)
                .build();
        user = userRepository.save(user);

        if (!isAdmin) {
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

            // Temporarily disabled email process
            // emailService.sendRegistrationNotificationToAdmin(student);
            
            return new MessageResponse("Registration Successful. Please wait for Admin approval.");
        }

        return new MessageResponse("Admin Registration Successful. You can log in immediately.");
    }

    @Override
    public AuthResponse login(AuthRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
        User user = userRepository.findByEmail(request.getEmail()).orElseThrow(() -> new RuntimeException("User not found"));
        
        // Enforce role check if role is provided
        if (request.getRole() != null && !request.getRole().isEmpty()) {
            if (!user.getUserType().name().equalsIgnoreCase(request.getRole())) {
                throw new RuntimeException("Login failed: Selected role does not match user account type.");
            }
        }

        if (user.getUserType() == UserType.STUDENT) {
            Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student profile not found"));
            if (student.getStatus() != StudentStatus.APPROVED && student.getStatus() != StudentStatus.ACTIVE) {
                throw new RuntimeException("Account is not approved yet. Status: " + student.getStatus());
            }
            UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
            String token = jwtUtil.generateToken(userDetails);
            return new AuthResponse(token, user.getUserType().name(), student.getProfileStatus().name(), "Login successful");
        }

        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        String token = jwtUtil.generateToken(userDetails);

        return new AuthResponse(token, user.getUserType().name(), "COMPLETED", "Login successful");
    }
}
