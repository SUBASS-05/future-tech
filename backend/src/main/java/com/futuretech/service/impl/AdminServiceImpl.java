package com.futuretech.service.impl;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentRequestDTO;
import com.futuretech.entity.Student;
import com.futuretech.entity.enums.StudentStatus;
import com.futuretech.repository.StudentRepository;
import com.futuretech.service.AdminService;
import com.futuretech.service.EmailService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {
    private final StudentRepository studentRepository;
    private final EmailService emailService;

    @Override
    public List<StudentRequestDTO> getPendingRequests() {
        return studentRepository.findByStatus(StudentStatus.PENDING_APPROVAL)
                .stream().map(student -> StudentRequestDTO.builder()
                        .studentId(student.getId())
                        .fullName(student.getFirstName() + " " + (student.getLastName() != null ? student.getLastName() : ""))
                        .email(student.getUser().getEmail())
                        .institutionName(student.getInstitution() != null ? student.getInstitution().getInstitutionName() : "N/A")
                        .tuitionJoiningDate(student.getTuitionJoiningDate() != null ? student.getTuitionJoiningDate().toLocalDate().toString() : null)
                        .status(student.getStatus().name())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    public List<StudentRequestDTO> getApprovedStudents() {
        List<StudentStatus> allowedStatuses = List.of(
                StudentStatus.APPROVED,
                StudentStatus.ACTIVE,
                StudentStatus.PENDING_APPROVAL
        );
        return studentRepository.findByStatusIn(allowedStatuses)
                .stream().map(student -> StudentRequestDTO.builder()
                        .studentId(student.getId())
                        .fullName((student.getFirstName() != null ? student.getFirstName() : "") + 
                                  (student.getLastName() != null && !student.getLastName().isEmpty() ? " " + student.getLastName() : ""))
                        .email(student.getUser() != null ? student.getUser().getEmail() : "")
                        .institutionName(student.getInstitution() != null ? student.getInstitution().getInstitutionName() : "N/A")
                        .tuitionJoiningDate(student.getTuitionJoiningDate() != null ? student.getTuitionJoiningDate().toLocalDate().toString() : null)
                        .status(student.getStatus().name())
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public MessageResponse approveStudent(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));
        student.setStatus(StudentStatus.APPROVED);
        studentRepository.save(student);
        return new MessageResponse("Student approved successfully");
    }

    @Override
    @Transactional
    public MessageResponse rejectStudent(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));
        student.setStatus(StudentStatus.REJECTED);
        studentRepository.save(student);
        return new MessageResponse("Student rejected");
    }
}
