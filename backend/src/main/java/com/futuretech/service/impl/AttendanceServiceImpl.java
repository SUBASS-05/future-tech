package com.futuretech.service.impl;
import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.entity.enums.*;
import com.futuretech.repository.*;
import com.futuretech.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {
    private final AttendanceRepository attendanceRepository;
    private final StudentRepository studentRepository;

    @Override
    public MessageResponse markAttendance(AttendanceRequest request) {
        if (attendanceRepository.existsByStudentIdAndAttendanceDate(request.getStudentId(), request.getAttendanceDate())) {
            throw new RuntimeException("Attendance already recorded for this date");
        }
        Student student = studentRepository.findById(request.getStudentId()).orElseThrow();
        Attendance att = Attendance.builder()
            .student(student)
            .attendanceDate(request.getAttendanceDate())
            .status(AttendanceStatus.valueOf(request.getStatus()))
            .remarks(request.getRemarks())
            .build();
        attendanceRepository.save(att);
        return new MessageResponse("Attendance recorded");
    }

    @Override
    public List<Attendance> getStudentAttendance(Long studentId) {
        return attendanceRepository.findByStudentId(studentId);
    }
}
