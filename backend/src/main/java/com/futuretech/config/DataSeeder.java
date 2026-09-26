package com.futuretech.config;
import com.futuretech.entity.User;
import com.futuretech.entity.enums.UserType;
import com.futuretech.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        if (userRepository.findByEmail("admin@futuretech.com").isEmpty()) {
            User admin = User.builder()
                    .name("Future Tech Admin")
                    .email("admin@futuretech.com")
                    .passwordHash(passwordEncoder.encode("admin123"))
                    .userType(UserType.ADMIN)
                    .isActive(true)
                    .build();
            userRepository.save(admin);
            System.out.println("Default Admin created: admin@futuretech.com / admin123");
        }
    }
}
