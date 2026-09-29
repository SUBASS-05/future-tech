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
import com.futuretech.service.FileStorageService;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import com.futuretech.dto.DepartmentDTO;
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
    private final FileStorageService fileStorageService;

    @Override
    public StudentProfileDTO getProfile(String email) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        return StudentProfileDTO.builder()
                .studentCode(student.getStudentCode())
                .tuitionJoiningDate(student.getTuitionJoiningDate() != null ? student.getTuitionJoiningDate().toLocalDate().toString() : null)
                .firstName(student.getFirstName())
                .lastName(student.getLastName())
                .email(user.getEmail())
                .phone(student.getPhone())
                .dateOfBirth(student.getDateOfBirth())
                .gender(student.getGender())
                .address(student.getAddress())
                .city(student.getCity())
                .pincode(student.getPincode())
                .educationType(student.getEducationType() != null ? student.getEducationType().name() : null)
                .institutionName(student.getInstitution() != null ? student.getInstitution().getInstitutionName() : null)
                .departmentName(student.getDepartment() != null ? student.getDepartment().getDepartmentName() : null)
                .institutionId(student.getInstitution() != null ? student.getInstitution().getId() : null)
                .departmentId(student.getDepartment() != null ? student.getDepartment().getId() : null)
                .classStandard(student.getClassStandard())
                .section(student.getSection())
                .academicYear(student.getAcademicYear())
                .joiningYear(student.getJoiningYear())
                .passingYear(student.getPassingYear())
                .academicBatch(student.getAcademicBatch())
                .parentName(student.getParentName())
                .parentRelationship(student.getParentRelationship())
                .parentPhone(student.getParentPhone())
                .alternativeParentPhone(student.getAlternativeParentPhone())
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
        student.setPincode(request.getPincode());
        student.setParentName(request.getParentName());
        student.setParentRelationship(request.getParentRelationship());
        student.setParentPhone(request.getParentPhone());
        student.setAlternativeParentPhone(request.getAlternativeParentPhone());
        student.setProfilePhotoUrl(request.getProfilePhotoUrl());

        if (request.getEducationType() != null) {
            student.setEducationType(EducationType.valueOf(request.getEducationType()));
        }

        if (request.getInstitutionId() != null) {
            Institution institution = institutionRepository.findById(request.getInstitutionId())
                    .orElseThrow(() -> new RuntimeException("Institution not found"));
            student.setInstitution(institution);
        }

        if (request.getDepartmentName() != null && !request.getDepartmentName().trim().isEmpty()) {
            if (student.getInstitution() != null) {
                String requestedName = request.getDepartmentName().trim();
                java.util.List<Department> depts = departmentRepository.findByInstitutionId(student.getInstitution().getId());
                Department matchedDept = depts.stream()
                        .filter(d -> d.getDepartmentName().equalsIgnoreCase(requestedName))
                        .findFirst()
                        .orElse(null);
                
                if (matchedDept == null) {
                    matchedDept = new Department();
                    matchedDept.setDepartmentName(requestedName);
                    matchedDept.setInstitution(student.getInstitution());
                    matchedDept = departmentRepository.save(matchedDept);
                }
                student.setDepartment(matchedDept);
            }
        } else if (request.getDepartmentId() != null) {
            Department dept = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new RuntimeException("Department not found"));
            student.setDepartment(dept);
        } else {
            student.setDepartment(null);
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
    
    @Override
    public java.util.List<com.futuretech.dto.InstitutionDTO> getInstitutions() {
        return institutionRepository.findAll().stream()
            .map(inst -> com.futuretech.dto.InstitutionDTO.builder()
                .id(inst.getId())
                .institutionName(inst.getInstitutionName())
                .institutionType(inst.getInstitutionType().name())
                .location(inst.getLocation())
                .build())
            .collect(java.util.stream.Collectors.toList());
    }

    @Override
    public List<DepartmentDTO> getDepartments(Long institutionId) {
        return departmentRepository.findByInstitutionId(institutionId).stream()
            .map(dept -> com.futuretech.dto.DepartmentDTO.builder()
                .id(dept.getId())
                .institutionId(dept.getInstitution().getId())
                .departmentName(dept.getDepartmentName())
                .departmentCode(dept.getDepartmentCode())
                .build())
            .collect(java.util.stream.Collectors.toList());
    }

    @Override
    @Transactional
    public MessageResponse uploadProfilePhoto(String email, MultipartFile file) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        
        // Validation for JPG/PNG and 5MB
        String contentType = file.getContentType();
        String originalFilename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        boolean isImage = false;
        
        if (contentType != null && (contentType.equals("image/jpeg") || contentType.equals("image/jpg") || contentType.equals("image/png"))) {
            isImage = true;
        } else if (originalFilename.endsWith(".jpg") || originalFilename.endsWith(".jpeg") || originalFilename.endsWith(".png")) {
            isImage = true;
        }

        if (!isImage) {
            throw new RuntimeException("Please select a valid image (JPG/PNG).");
        }
        if (file.getSize() > 5 * 1024 * 1024) {
            throw new RuntimeException("Image is too large. Please select an image below 5 MB.");
        }

        // Delete old photo if exists
        if (student.getProfilePhotoUrl() != null) {
            fileStorageService.deleteFile(student.getProfilePhotoUrl());
        }

        String fileUrl = fileStorageService.storeFile(file);
        student.setProfilePhotoUrl(fileUrl);
        studentRepository.save(student);

        return new MessageResponse("Profile photo updated successfully");
    }

    @Override
    @Transactional
    public MessageResponse removeProfilePhoto(String email) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        
        if (student.getProfilePhotoUrl() != null) {
            fileStorageService.deleteFile(student.getProfilePhotoUrl());
            student.setProfilePhotoUrl(null);
            studentRepository.save(student);
        }

        return new MessageResponse("Profile photo removed successfully");
    }
}

