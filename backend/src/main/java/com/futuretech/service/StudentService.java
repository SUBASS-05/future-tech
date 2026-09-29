package com.futuretech.service;
import com.futuretech.dto.MessageResponse;
import com.futuretech.dto.StudentProfileDTO;
import com.futuretech.dto.UpdateProfileRequest;
import com.futuretech.dto.InstitutionDTO;
import com.futuretech.dto.DepartmentDTO;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

public interface StudentService {
    StudentProfileDTO getProfile(String email);
    MessageResponse updateProfile(String email, UpdateProfileRequest request);
    List<InstitutionDTO> getInstitutions();
    List<DepartmentDTO> getDepartments(Long institutionId);
    MessageResponse uploadProfilePhoto(String email, MultipartFile file);
    MessageResponse removeProfilePhoto(String email);
}
