package com.futuretech.controller;
import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.repository.*;
import com.futuretech.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
public class StudentFeatureController {
    private final FinanceService financeService;
    private final AttendanceService attendanceService;
    private final TaskService taskService;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;

    private Long getStudentId(String email) {
        User user = userRepository.findByEmail(email).orElseThrow();
        return studentRepository.findByUserId(user.getId()).orElseThrow().getId();
    }

    @GetMapping("/fees")
    public ResponseEntity<List<FeeRecord>> getFees(Authentication auth) {
        return ResponseEntity.ok(financeService.getStudentFees(getStudentId(auth.getName())));
    }
    @GetMapping("/payments")
    public ResponseEntity<List<Payment>> getPayments(Authentication auth) {
        return ResponseEntity.ok(financeService.getStudentPayments(getStudentId(auth.getName())));
    }
    @GetMapping("/attendance")
    public ResponseEntity<List<Attendance>> getAttendance(Authentication auth) {
        return ResponseEntity.ok(attendanceService.getStudentAttendance(getStudentId(auth.getName())));
    }
    @GetMapping("/tasks")
    public ResponseEntity<List<StudentTask>> getTasks(Authentication auth) {
        return ResponseEntity.ok(taskService.getStudentTasks(auth.getName()));
    }
    @PutMapping("/tasks/{taskId}/status")
    public ResponseEntity<MessageResponse> updateTask(Authentication auth, @PathVariable Long taskId, @RequestBody TaskStatusUpdateRequest req) {
        return ResponseEntity.ok(taskService.updateTaskStatus(auth.getName(), taskId, req.getStatus()));
    }
}
