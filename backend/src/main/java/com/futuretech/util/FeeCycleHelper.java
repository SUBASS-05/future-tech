package com.futuretech.util;

import com.futuretech.entity.Student;
import java.math.BigDecimal;
import java.time.LocalDate;

public class FeeCycleHelper {
    public static final BigDecimal ANNUAL_FEE = new BigDecimal("15000");

    public static LocalDate getTuitionJoiningDate(Student student) {
        if (student.getTuitionJoiningDate() != null) {
            return student.getTuitionJoiningDate().toLocalDate();
        } else if (student.getCreatedAt() != null) {
            return student.getCreatedAt().toLocalDate();
        } else {
            return LocalDate.now();
        }
    }

    public static LocalDate[] calculateFeeCycle(LocalDate joiningDate, LocalDate currentDate) {
        if (currentDate.isBefore(joiningDate)) {
            LocalDate cycleStart = joiningDate;
            LocalDate cycleEnd = joiningDate.plusYears(1).minusDays(1);
            return new LocalDate[]{cycleStart, cycleEnd};
        }
        int years = currentDate.getYear() - joiningDate.getYear();
        LocalDate candidateStart = joiningDate.plusYears(years);
        if (currentDate.isBefore(candidateStart)) {
            candidateStart = joiningDate.plusYears(years - 1);
        }
        LocalDate candidateEnd = candidateStart.plusYears(1).minusDays(1);
        return new LocalDate[]{candidateStart, candidateEnd};
    }
}
