package com.futuretech.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class AuthResponse {
    private String token;
    private String userType;
    private String message;
}
