package com.futuretech.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "payment_id", unique = true, nullable = false)
    private String paymentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fee_record_id", nullable = true)
    private FeeRecord feeRecord;

    @Column(name = "fee_cycle_start", nullable = false)
    private LocalDate feeCycleStart;

    @Column(name = "fee_cycle_end", nullable = false)
    private LocalDate feeCycleEnd;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(name = "payment_proof_url", nullable = false)
    private String paymentProofUrl;

    @Column(name = "payment_date", nullable = false)
    private LocalDateTime paymentDate;

    @Column(name = "is_seen_by_top_admin", nullable = false)
    @Builder.Default
    private Boolean isSeenByTopAdmin = false;

    @Column(name = "seen_at")
    private LocalDateTime seenAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (paymentDate == null) {
            paymentDate = LocalDateTime.now();
        }
        if (isSeenByTopAdmin == null) {
            isSeenByTopAdmin = false;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
