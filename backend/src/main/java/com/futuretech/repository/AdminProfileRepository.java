package com.futuretech.repository;
import com.futuretech.entity.AdminProfile;
import com.futuretech.entity.enums.AdminStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface AdminProfileRepository extends JpaRepository<AdminProfile, Long> {
    Optional<AdminProfile> findByUserId(Long userId);
    List<AdminProfile> findByStatusIn(List<AdminStatus> statuses);
    long countByStatusIn(List<AdminStatus> statuses);
}
