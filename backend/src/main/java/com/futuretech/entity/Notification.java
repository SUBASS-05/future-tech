package com.futuretech.entity;
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
