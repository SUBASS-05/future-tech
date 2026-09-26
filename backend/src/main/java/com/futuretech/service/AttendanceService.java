package com.futuretech.service;
import com.futuretech.dto.*;
import com.futuretech.entity.Attendance;
import java.util.List;
public interface AttendanceService {
    MessageResponse markAttendance(AttendanceRequest request);
    List<Attendance> getStudentAttendance(Long studentId);
}
