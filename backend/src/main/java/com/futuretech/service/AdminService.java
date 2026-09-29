package com.futuretech.service;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentRequestDTO;
import java.util.List;

public interface AdminService {
    List<StudentRequestDTO> getPendingRequests();
    List<StudentRequestDTO> getApprovedStudents();
    MessageResponse approveStudent(Long studentId);
    MessageResponse rejectStudent(Long studentId);
}

