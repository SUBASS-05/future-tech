package com.futuretech.entity;
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
