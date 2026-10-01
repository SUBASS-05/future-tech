package com.futuretech.service.impl;

import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.entity.enums.*;
import com.futuretech.repository.*;
import com.futuretech.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {
    private final AttendanceRepository attendanceRepository;
    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final LeaveRequestRepository leaveRequestRepository;

    @Override
    public DailyAttendanceResponse getDailyAttendance(LocalDate date) {
        if (date == null) date = LocalDate.now();

        List<Student> students = studentRepository.findAll();
        List<Attendance> attendanceList = attendanceRepository.findByAttendanceDate(date);
        Map<Long, Attendance> attendanceMap = attendanceList.stream()
                .collect(Collectors.toMap(a -> a.getStudent().getId(), a -> a, (a1, a2) -> a1));

        List<LeaveRequest> approvedLeaves = leaveRequestRepository.findApprovedLeavesOnDate(date, LeaveStatus.APPROVED);
        Set<Long> leaveStudentIds = approvedLeaves.stream()
                .map(l -> l.getStudent().getId())
                .collect(Collectors.toSet());

        int presentCount = 0;
        int absentCount = 0;
        int leaveCount = 0;
        int notMarkedCount = 0;

        List<AttendanceRecordDTO> records = new ArrayList<>();

        for (Student s : students) {
            Attendance att = attendanceMap.get(s.getId());
            String status = "NOT_MARKED";
            String remarks = null;
            Long attendanceId = null;

            if (att != null) {
                status = att.getStatus().name();
                remarks = att.getRemarks();
                attendanceId = att.getId();
            } else if (leaveStudentIds.contains(s.getId())) {
                status = "LEAVE";
                remarks = "Approved Leave";
            }

            switch (status) {
                case "PRESENT":
                    presentCount++;
                    break;
                case "ABSENT":
                    absentCount++;
                    break;
                case "LEAVE":
                    leaveCount++;
                    break;
                case "NOT_MARKED":
                default:
                    notMarkedCount++;
                    break;
            }

            String fullName = (s.getFirstName() != null ? s.getFirstName() : "") + " " + (s.getLastName() != null ? s.getLastName() : "");
            if (fullName.trim().isEmpty() && s.getUser() != null) {
                fullName = s.getUser().getName();
            }

            records.add(AttendanceRecordDTO.builder()
                    .attendanceId(attendanceId)
                    .studentId(s.getId())
                    .studentCode(s.getStudentCode())
                    .studentName(fullName.trim())
                    .department(getDeptName(s))
                    .institution(getInstName(s))
                    .attendanceDate(date)
                    .status(status)
                    .remarks(remarks)
                    .build());
        }

        double rate = 0.0;
        int evaluated = presentCount + absentCount;
        if (evaluated > 0) {
            rate = Math.round((double) presentCount / evaluated * 10000.0) / 100.0;
        }

        return DailyAttendanceResponse.builder()
                .date(date)
                .totalStudents(students.size())
                .presentCount(presentCount)
                .absentCount(absentCount)
                .leaveCount(leaveCount)
                .notMarkedCount(notMarkedCount)
                .attendanceRate(rate)
                .records(records)
                .build();
    }

    @Override
    @Transactional
    public MessageResponse markAttendance(MarkAttendanceRequest request) {
        if (request.getStudentId() == null) throw new RuntimeException("Student ID is required");
        if (request.getAttendanceDate() == null) throw new RuntimeException("Attendance date is required");
        if (request.getAttendanceDate().isAfter(LocalDate.now())) {
            throw new RuntimeException("Cannot mark or modify attendance for future dates");
        }

        Student student = studentRepository.findById(request.getStudentId())
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Optional<Attendance> existingOpt = attendanceRepository.findByStudentIdAndAttendanceDate(request.getStudentId(), request.getAttendanceDate());

        String statusStr = request.getStatus() != null ? request.getStatus().toUpperCase() : "NOT_MARKED";

        if (statusStr.equals("NOT_MARKED")) {
            existingOpt.ifPresent(attendanceRepository::delete);
            return new MessageResponse("Attendance set to Not Marked");
        }

        AttendanceStatus statusEnum;
        try {
            statusEnum = AttendanceStatus.valueOf(statusStr);
        } catch (IllegalArgumentException e) {
            statusEnum = AttendanceStatus.PRESENT;
        }

        Attendance att;
        if (existingOpt.isPresent()) {
            att = existingOpt.get();
            att.setStatus(statusEnum);
            att.setRemarks(request.getRemarks());
        } else {
            att = Attendance.builder()
                    .student(student)
                    .attendanceDate(request.getAttendanceDate())
                    .status(statusEnum)
                    .remarks(request.getRemarks())
                    .build();
        }

        attendanceRepository.save(att);
        return new MessageResponse("Attendance marked successfully");
    }

    @Override
    @Transactional
    public MessageResponse bulkMarkAttendance(BulkMarkAttendanceRequest request) {
        LocalDate date = request.getAttendanceDate() != null ? request.getAttendanceDate() : LocalDate.now();
        if (date.isAfter(LocalDate.now())) {
            throw new RuntimeException("Cannot mark or modify attendance for future dates");
        }
        String targetStatusStr = request.getStatus() != null ? request.getStatus().toUpperCase() : "PRESENT";
        AttendanceStatus statusEnum = AttendanceStatus.valueOf(targetStatusStr);

        List<Student> studentsToMark;
        if (request.getStudentIds() != null && !request.getStudentIds().isEmpty()) {
            studentsToMark = studentRepository.findAllById(request.getStudentIds());
        } else {
            List<Student> allStudents = studentRepository.findAll();
            List<Attendance> existing = attendanceRepository.findByAttendanceDate(date);
            Set<Long> markedIds = existing.stream().map(a -> a.getStudent().getId()).collect(Collectors.toSet());
            
            List<LeaveRequest> approvedLeaves = leaveRequestRepository.findApprovedLeavesOnDate(date, LeaveStatus.APPROVED);
            Set<Long> leaveIds = approvedLeaves.stream().map(l -> l.getStudent().getId()).collect(Collectors.toSet());

            studentsToMark = allStudents.stream()
                    .filter(s -> !markedIds.contains(s.getId()) && !leaveIds.contains(s.getId()))
                    .collect(Collectors.toList());
        }

        for (Student s : studentsToMark) {
            Optional<Attendance> existingOpt = attendanceRepository.findByStudentIdAndAttendanceDate(s.getId(), date);
            Attendance att = existingOpt.orElseGet(() -> Attendance.builder()
                    .student(s)
                    .attendanceDate(date)
                    .build());
            att.setStatus(statusEnum);
            att.setRemarks(request.getRemarks());
            attendanceRepository.save(att);
        }

        return new MessageResponse("Bulk attendance marked for " + studentsToMark.size() + " students");
    }

    @Override
    public StudentAttendanceSummaryResponse getStudentAttendanceSummary(Long studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));
        return buildSummary(s);
    }

    @Override
    public StudentAttendanceSummaryResponse getMyAttendanceSummary(String studentEmail) {
        User user = userRepository.findByEmail(studentEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Student s = studentRepository.findByUserId(user.getId())
                .orElseThrow(() -> new RuntimeException("Student not found"));
        return buildSummary(s);
    }

    @Override
    public List<Attendance> getStudentAttendance(Long studentId) {
        return attendanceRepository.findByStudentId(studentId);
    }

    private String getDeptName(Student s) {
        return s.getDepartment() != null ? s.getDepartment().getDepartmentName() : null;
    }

    private String getInstName(Student s) {
        return s.getInstitution() != null ? s.getInstitution().getInstitutionName() : null;
    }

    private StudentAttendanceSummaryResponse buildSummary(Student s) {
        List<Attendance> attendanceList = attendanceRepository.findByStudentId(s.getId());
        List<LeaveRequest> approvedLeaves = leaveRequestRepository.findByStudentIdOrderByCreatedAtDesc(s.getId()).stream()
                .filter(l -> l.getStatus() == LeaveStatus.APPROVED)
                .collect(Collectors.toList());

        int present = 0;
        int absent = 0;
        int leave = 0;

        List<AttendanceRecordDTO> history = new ArrayList<>();

        String fullName = (s.getFirstName() != null ? s.getFirstName() : "") + " " + (s.getLastName() != null ? s.getLastName() : "");
        if (fullName.trim().isEmpty() && s.getUser() != null) {
            fullName = s.getUser().getName();
        }

        for (Attendance a : attendanceList) {
            if (a.getStatus() == AttendanceStatus.PRESENT) present++;
            else if (a.getStatus() == AttendanceStatus.ABSENT) absent++;
            else if (a.getStatus() == AttendanceStatus.LEAVE) leave++;

            history.add(AttendanceRecordDTO.builder()
                    .attendanceId(a.getId())
                    .studentId(s.getId())
                    .studentCode(s.getStudentCode())
                    .studentName(fullName.trim())
                    .department(getDeptName(s))
                    .institution(getInstName(s))
                    .attendanceDate(a.getAttendanceDate())
                    .status(a.getStatus().name())
                    .remarks(a.getRemarks())
                    .build());
        }

        int evaluated = present + absent;
        double percentage = evaluated > 0 ? Math.round((double) present / evaluated * 10000.0) / 100.0 : 0.0;

        return StudentAttendanceSummaryResponse.builder()
                .studentId(s.getId())
                .studentCode(s.getStudentCode())
                .studentName(fullName.trim())
                .department(getDeptName(s))
                .institution(getInstName(s))
                .totalEvaluatedDays(evaluated)
                .presentCount(present)
                .absentCount(absent)
                .leaveCount(leave)
                .notMarkedCount(0)
                .attendancePercentage(percentage)
                .history(history)
                .monthlyStats(new HashMap<>())
                .build();
    }

    @Override
    public List<LowAttendanceStudentDTO> getLowAttendanceStudents(double thresholdPercentage) {
        List<Student> students = studentRepository.findAll();
        List<LowAttendanceStudentDTO> result = new ArrayList<>();

        for (Student s : students) {
            StudentAttendanceSummaryResponse summary = buildSummary(s);
            if (summary.getTotalEvaluatedDays() > 0 && summary.getAttendancePercentage() < thresholdPercentage) {
                result.add(LowAttendanceStudentDTO.builder()
                        .studentId(s.getId())
                        .studentCode(s.getStudentCode())
                        .studentName(summary.getStudentName())
                        .department(getDeptName(s))
                        .institution(getInstName(s))
                        .presentCount(summary.getPresentCount())
                        .absentCount(summary.getAbsentCount())
                        .leaveCount(summary.getLeaveCount())
                        .attendancePercentage(summary.getAttendancePercentage())
                        .build());
            }
        }
        return result;
    }
}
