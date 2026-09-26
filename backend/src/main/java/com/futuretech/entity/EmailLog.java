package com.futuretech.entity;
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
