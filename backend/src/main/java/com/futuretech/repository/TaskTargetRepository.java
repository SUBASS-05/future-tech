package com.futuretech.repository;
import com.futuretech.entity.TaskTarget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TaskTargetRepository extends JpaRepository<TaskTarget, Long> {
    List<TaskTarget> findByTaskId(Long taskId);
}
