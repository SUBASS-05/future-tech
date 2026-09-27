package com.futuretech.dto;
import lombok.Data;
@Data
public class RegisterRequest {
    private String fullName;
    private String email;
    private String password;
    private String institutionName;
    private String role;
}
