import os

base_path = "d:/future tech/backend/src/main/java/com/futuretech"
entity_path = os.path.join(base_path, "entity")
enums_path = os.path.join(entity_path, "enums")
repo_path = os.path.join(base_path, "repository")

enums = {
    "UserType.java": """package com.futuretech.entity.enums;
public enum UserType { ADMIN, STUDENT }
""",
    "InstitutionType.java": """package com.futuretech.entity.enums;
public enum InstitutionType { SCHOOL, COLLEGE }
""",
    "EducationType.java": """package com.futuretech.entity.enums;
public enum EducationType { SCHOOL, ENGINEERING, ARTS_SCIENCE, POLYTECHNIC, OTHER }
""",
    "ProfileStatus.java": """package com.futuretech.entity.enums;
public enum ProfileStatus { INCOMPLETE, COMPLETED }
""",
    "StudentStatus.java": """package com.futuretech.entity.enums;
public enum StudentStatus { PENDING_APPROVAL, APPROVED, REJECTED, ACTIVE, INACTIVE }
""",
    "FeeStatus.java": """package com.futuretech.entity.enums;
public enum FeeStatus { PENDING, PARTIALLY_PAID, PAID, OVERDUE, CANCELLED }
""",
    "PaymentMethod.java": """package com.futuretech.entity.enums;
public enum PaymentMethod { CASH, UPI, BANK_TRANSFER, CARD }
""",
    "AttendanceStatus.java": """package com.futuretech.entity.enums;
public enum AttendanceStatus { PRESENT, ABSENT }
""",
    "TargetType.java": """package com.futuretech.entity.enums;
public enum TargetType { ALL_STUDENTS, STUDENT, INSTITUTION, DEPARTMENT, ACADEMIC_BATCH }
""",
    "TaskStatus.java": """package com.futuretech.entity.enums;
public enum TaskStatus { PENDING, IN_PROGRESS, COMPLETED }
""",
    "EmailType.java": """package com.futuretech.entity.enums;
public enum EmailType { STUDENT_REGISTRATION, STUDENT_APPROVAL }
""",
    "EmailStatus.java": """package com.futuretech.entity.enums;
public enum EmailStatus { PENDING, SENT, FAILED }
"""
}

entities = {
    "User.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.UserType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false) private String name;
    @Column(nullable = false, unique = true) private String email;
    @Column(name = "password_hash", nullable = false) private String passwordHash;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "user_type", nullable = false) private UserType userType;
    
    private String phone;
    @Column(name = "is_active") private Boolean isActive = true;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
""",
    "Institution.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.InstitutionType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "institutions")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Institution {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "institution_name", nullable = false) private String institutionName;
    @Enumerated(EnumType.STRING)
    @Column(name = "institution_type", nullable = false) private InstitutionType institutionType;
    
    private String location;
    @Column(name = "is_active") private Boolean isActive = true;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
""",
    "Department.java": """package com.futuretech.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "departments")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Department {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "institution_id")
    private Institution institution;
    
    @Column(name = "department_name", nullable = false) private String departmentName;
    @Column(name = "department_code") private String departmentCode;
    @Column(name = "is_active") private Boolean isActive = true;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
""",
    "Student.java": """package com.futuretech.entity;
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
""",
    "FeeRecord.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.FeeStatus;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "fee_records")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class FeeRecord {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;
    
    @Column(name = "fee_name", nullable = false) private String feeName;
    @Column(name = "total_amount", nullable = false) private BigDecimal totalAmount;
    @Column(name = "discount_amount") private BigDecimal discountAmount;
    @Column(name = "final_amount", nullable = false) private BigDecimal finalAmount;
    
    @Column(name = "due_date") private LocalDate dueDate;
    
    @Enumerated(EnumType.STRING)
    private FeeStatus status = FeeStatus.PENDING;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
""",
    "Payment.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.PaymentMethod;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Payment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fee_record_id", nullable = false)
    private FeeRecord feeRecord;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;
    
    @Column(nullable = false) private BigDecimal amount;
    @Column(name = "payment_date", nullable = false) private LocalDate paymentDate;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false) private PaymentMethod paymentMethod;
    
    @Column(name = "transaction_id") private String transactionId;
    @Column(name = "receipt_number", unique = true) private String receiptNumber;
    private String remarks;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); }
}
""",
    "Attendance.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.AttendanceStatus;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Attendance {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;
    
    @Column(name = "attendance_date", nullable = false) private LocalDate attendanceDate;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false) private AttendanceStatus status;
    
    private String remarks;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); }
}
""",
    "Task.java": """package com.futuretech.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "tasks")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Task {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false) private String title;
    private String description;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;
    
    @Column(name = "created_date", nullable = false) private LocalDate createdDate;
    @Column(name = "due_date") private LocalDate dueDate;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
""",
    "TaskTarget.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.TargetType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "task_targets")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class TaskTarget {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false) private TargetType targetType;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id")
    private Student student;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "institution_id")
    private Institution institution;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;
    
    @Column(name = "academic_batch") private String academicBatch;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); }
}
""",
    "StudentTask.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.TaskStatus;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "student_tasks")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class StudentTask {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;
    
    @Enumerated(EnumType.STRING)
    private TaskStatus status = TaskStatus.PENDING;
    
    @Column(name = "completed_at") private LocalDateTime completedAt;
    private String remarks;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); updatedAt = LocalDateTime.now(); }
    @PreUpdate protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
""",
    "Notification.java": """package com.futuretech.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;
    
    @Column(nullable = false) private String title;
    @Column(nullable = false) private String message;
    @Column(name = "notification_type") private String notificationType;
    
    @Column(name = "is_read") private Boolean isRead = false;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); }
}
""",
    "EmailLog.java": """package com.futuretech.entity;
import com.futuretech.entity.enums.EmailStatus;
import com.futuretech.entity.enums.EmailType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "email_logs")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class EmailLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id")
    private Student student;
    
    @Column(nullable = false) private String email;
    private String subject;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "email_type", nullable = false) private EmailType emailType;
    
    @Enumerated(EnumType.STRING)
    private EmailStatus status = EmailStatus.PENDING;
    
    @Column(name = "sent_at") private LocalDateTime sentAt;
    @Column(name = "error_message") private String errorMessage;
    
    @Column(name = "created_at", updatable = false) private LocalDateTime createdAt;
    
    @PrePersist protected void onCreate() { createdAt = LocalDateTime.now(); }
}
"""
}

repos = {
    "UserRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
""",
    "InstitutionRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Institution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InstitutionRepository extends JpaRepository<Institution, Long> {}
""",
    "DepartmentRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, Long> {}
""",
    "StudentRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByStudentCode(String studentCode);
    Optional<Student> findByUserId(Long userId);
}
""",
    "FeeRecordRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.FeeRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FeeRecordRepository extends JpaRepository<FeeRecord, Long> {
    List<FeeRecord> findByStudentId(Long studentId);
}
""",
    "PaymentRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    List<Payment> findByStudentId(Long studentId);
}
""",
    "AttendanceRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.time.LocalDate;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    List<Attendance> findByStudentId(Long studentId);
    boolean existsByStudentIdAndAttendanceDate(Long studentId, LocalDate attendanceDate);
}
""",
    "TaskRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {}
""",
    "TaskTargetRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.TaskTarget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TaskTargetRepository extends JpaRepository<TaskTarget, Long> {
    List<TaskTarget> findByTaskId(Long taskId);
}
""",
    "StudentTaskRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.StudentTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface StudentTaskRepository extends JpaRepository<StudentTask, Long> {
    List<StudentTask> findByStudentId(Long studentId);
}
""",
    "NotificationRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByStudentId(Long studentId);
}
""",
    "EmailLogRepository.java": """package com.futuretech.repository;
import com.futuretech.entity.EmailLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EmailLogRepository extends JpaRepository<EmailLog, Long> {}
"""
}

# Write Enums
for name, content in enums.items():
    with open(os.path.join(enums_path, name), "w", encoding="utf-8") as f:
        f.write(content)

# Write Entities
for name, content in entities.items():
    with open(os.path.join(entity_path, name), "w", encoding="utf-8") as f:
        f.write(content)

# Write Repos
for name, content in repos.items():
    with open(os.path.join(repo_path, name), "w", encoding="utf-8") as f:
        f.write(content)

print("Java Entities and Repositories generated successfully.")
