package com.futuretech.repository;

import com.futuretech.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    List<Payment> findByStudentIdOrderByPaymentDateDesc(Long studentId);

    List<Payment> findByStudentIdAndFeeCycleStartAndFeeCycleEnd(Long studentId, LocalDate feeCycleStart, LocalDate feeCycleEnd);

    List<Payment> findByPaymentDateBetweenOrderByPaymentDateDesc(LocalDateTime start, LocalDateTime end);

    @Query("SELECT p FROM Payment p WHERE p.paymentDate >= :start AND p.paymentDate <= :end " +
           "AND (LOWER(p.student.firstName) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(p.student.lastName) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(p.student.user.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(p.student.studentCode) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(CONCAT(p.student.firstName, ' ', p.student.lastName)) LIKE LOWER(CONCAT('%', :query, '%'))) " +
           "ORDER BY p.paymentDate DESC")
    List<Payment> findByPaymentDateBetweenAndSearchQuery(@Param("start") LocalDateTime start, 
                                                         @Param("end") LocalDateTime end, 
                                                         @Param("query") String query);

    long countByIsSeenByTopAdminFalse();

    List<Payment> findByIsSeenByTopAdminFalse();
}
