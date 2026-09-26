package com.futuretech.service.impl;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentProfileDTO;
import com.futuretech.dto.UpdateProfileRequest;
import com.futuretech.entity.Department;
import com.futuretech.entity.Institution;
import com.futuretech.entity.Student;
import com.futuretech.entity.User;
import com.futuretech.entity.enums.EducationType;
import com.futuretech.entity.enums.ProfileStatus;
import com.futuretech.repository.DepartmentRepository;
import com.futuretech.repository.InstitutionRepository;
import com.futuretech.repository.StudentRepository;
import com.futuretech.repository.UserRepository;
import com.futuretech.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class StudentServiceImpl implements StudentService {
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final InstitutionRepository institutionRepository;
    private final DepartmentRepository departmentRepository;

    @Override
    public StudentProfileDTO getProfile(String email) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        return StudentProfileDTO.builder()
                .studentCode(student.getStudentCode())
                .firstName(student.getFirstName())
                .lastName(student.getLastName())
                .email(user.getEmail())
                .phone(student.getPhone())
                .dateOfBirth(student.getDateOfBirth())
                .gender(student.getGender())
                .address(student.getAddress())
                .city(student.getCity())
                .educationType(student.getEducationType() != null ? student.getEducationType().name() : null)
                .institutionName(student.getInstitution() != null ? student.getInstitution().getInstitutionName() : null)
                .departmentName(student.getDepartment() != null ? student.getDepartment().getDepartmentName() : null)
                .classStandard(student.getClassStandard())
                .section(student.getSection())
                .academicYear(student.getAcademicYear())
                .joiningYear(student.getJoiningYear())
                .passingYear(student.getPassingYear())
                .academicBatch(student.getAcademicBatch())
                .parentName(student.getParentName())
                .parentPhone(student.getParentPhone())
                .profilePhotoUrl(student.getProfilePhotoUrl())
                .profileStatus(student.getProfileStatus().name())
                .status(student.getStatus().name())
                .build();
    }

    @Override
    @Transactional
    public MessageResponse updateProfile(String email, UpdateProfileRequest request) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));

        student.setFirstName(request.getFirstName());
        student.setLastName(request.getLastName());
        student.setDateOfBirth(request.getDateOfBirth());
        student.setGender(request.getGender());
        student.setPhone(request.getPhone());
        student.setAddress(request.getAddress());
        student.setCity(request.getCity());
        student.setParentName(request.getParentName());
        student.setParentPhone(request.getParentPhone());
        student.setProfilePhotoUrl(request.getProfilePhotoUrl());

        if (request.getEducationType() != null) {
            student.setEducationType(EducationType.valueOf(request.getEducationType()));
        }

        if (request.getInstitutionId() != null) {
            Institution institution = institutionRepository.findById(request.getInstitutionId())
                    .orElseThrow(() -> new RuntimeException("Institution not found"));
            student.setInstitution(institution);
        }

        if (request.getDepartmentId() != null) {
            Department dept = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new RuntimeException("Department not found"));
            student.setDepartment(dept);
        }

        student.setClassStandard(request.getClassStandard());
        student.setSection(request.getSection());
        student.setAcademicYear(request.getAcademicYear());

        student.setJoiningYear(request.getJoiningYear());
        student.setPassingYear(request.getPassingYear());

        // Core Academic Batch Calculation Rule
        if (request.getJoiningYear() != null && request.getPassingYear() != null) {
            if (request.getPassingYear() <= request.getJoiningYear()) {
                throw new RuntimeException("Passing year must be greater than joining year");
            }
            student.setAcademicBatch(request.getJoiningYear() + "-" + request.getPassingYear());
        }

        student.setProfileStatus(ProfileStatus.COMPLETED);
        studentRepository.save(student);

        return new MessageResponse("Profile updated successfully");
    }
}
