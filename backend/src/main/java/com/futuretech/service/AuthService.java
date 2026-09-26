package com.futuretech.service;
import com.futuretech.dto.AuthRequest;
import com.futuretech.dto.AuthResponse;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.RegisterRequest;

public interface AuthService {
    MessageResponse registerStudent(RegisterRequest request);
    AuthResponse login(AuthRequest request);
}
