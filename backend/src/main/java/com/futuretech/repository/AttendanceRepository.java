package com.futuretech.repository;
import com.futuretech.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.time.LocalDate;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    List<Attendance> findByStudentId(Long studentId);
    boolean existsByStudentIdAndAttendanceDate(Long studentId, LocalDate attendanceDate);
}
