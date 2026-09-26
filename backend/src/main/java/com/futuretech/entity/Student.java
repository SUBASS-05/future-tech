package com.futuretech.entity;
import com.futuretech.entity.enums.*;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "students")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Student {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(name = "student_code", unique = true) private String studentCode;
    @Column(name = "first_name") private String firstName;
    @Column(name = "last_name") private String lastName;
    @Column(name = "date_of_birth") private LocalDate dateOfBirth;
    private String gender;
    private String phone;
    private String address;
    private String city;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "education_type") private EducationType educationType;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "institution_id")
    private Institution institution;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;
    
    @Column(name = "class_standard") private String classStandard;
    private String section;
    @Column(name = "academic_year") private String academicYear;
    
    @Column(name = "joining_year") private Integer joiningYear;
    @Column(name = "passing_year") private Integer passingYear;
    @Column(name = "academic_batch") private String academicBatch;
    
    @Column(name = "parent_name") private String parentName;
    @Column(name = "parent_phone") private String parentPhone;
    @Column(name = "profile_photo_url") private String profilePhotoUrl;
    @Column(name = "joining_date") private LocalDate joiningDate;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "profile_status") private ProfileStatus profileStatus = ProfileStatus.INCOMPLETE;
    
    @Enumerated(EnumType.STRING)
    private StudentStatus status = StudentStatus.PENDING_APPROVAL;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
