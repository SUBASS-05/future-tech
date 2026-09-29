package com.futuretech.repository;

import com.futuretech.entity.TaskAssignment;
import com.futuretech.entity.enums.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TaskAssignmentRepository extends JpaRepository<TaskAssignment, Long> {
    List<TaskAssignment> findByTaskId(Long taskId);
    List<TaskAssignment> findByStudentId(Long studentId);
    Optional<TaskAssignment> findByTaskIdAndStudentId(Long taskId, Long studentId);
    void deleteByTaskIdAndStudentId(Long taskId, Long studentId);
    void deleteByTaskId(Long taskId);
}
