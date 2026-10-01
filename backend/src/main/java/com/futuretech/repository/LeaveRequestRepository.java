package com.futuretech.repository;

import com.futuretech.entity.LeaveRequest;
import com.futuretech.entity.enums.LeaveStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Long> {
    List<LeaveRequest> findByStudentIdOrderByCreatedAtDesc(Long studentId);
    List<LeaveRequest> findByStatusOrderByCreatedAtDesc(LeaveStatus status);
    List<LeaveRequest> findAllByOrderByCreatedAtDesc();

    @Query("SELECT l FROM LeaveRequest l WHERE l.student.id = :studentId AND l.status = :status AND :date BETWEEN l.startDate AND l.endDate")
    List<LeaveRequest> findApprovedLeavesForStudentOnDate(
            @Param("studentId") Long studentId,
            @Param("date") LocalDate date,
            @Param("status") LeaveStatus status
    );

    @Query("SELECT l FROM LeaveRequest l WHERE l.status = :status AND :date BETWEEN l.startDate AND l.endDate")
    List<LeaveRequest> findApprovedLeavesOnDate(
            @Param("date") LocalDate date,
            @Param("status") LeaveStatus status
    );
}
