package com.futuretech.entity;
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
