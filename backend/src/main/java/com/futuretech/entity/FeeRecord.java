package com.futuretech.entity;
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
