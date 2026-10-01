package com.futuretech;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootApplication
public class FuturetechApplication {

    public static void main(String[] args) {
        SpringApplication.run(FuturetechApplication.class, args);
    }

    @Bean
    public CommandLineRunner initDatabaseSchema(JdbcTemplate jdbcTemplate) {
        return args -> {
            try {
                jdbcTemplate.execute("ALTER TABLE attendance MODIFY COLUMN status VARCHAR(50) NOT NULL");
            } catch (Exception e) {
                System.out.println("Attendance table column update notice: " + e.getMessage());
            }
            try {
                jdbcTemplate.execute("ALTER TABLE leave_requests MODIFY COLUMN status VARCHAR(50) NOT NULL");
            } catch (Exception e) {
                System.out.println("Leave requests table column update notice: " + e.getMessage());
            }
        };
    }
}
