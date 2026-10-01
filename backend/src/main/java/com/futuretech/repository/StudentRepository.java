package com.futuretech.repository;
import com.futuretech.entity.Student;
import com.futuretech.entity.enums.StudentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByStudentCode(String studentCode);
    Optional<Student> findByUserId(Long userId);
    List<Student> findByStatus(StudentStatus status);
    List<Student> findByStatusIn(List<StudentStatus> statuses);
}
