package com.futuretech.entity;
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
