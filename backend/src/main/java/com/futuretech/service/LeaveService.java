package com.futuretech.service;

import com.futuretech.dto.*;

import java.util.List;

public interface LeaveService {
    MessageResponse applyLeave(String studentEmail, CreateLeaveRequest request);
    List<LeaveRequestDTO> getMyLeaveRequests(String studentEmail);
    List<LeaveRequestDTO> getAllLeaveRequests(String status);
    MessageResponse reviewLeaveRequest(String adminEmail, Long leaveId, ReviewLeaveRequest request);
}
