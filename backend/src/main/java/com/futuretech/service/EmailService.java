package com.futuretech.service;
import com.futuretech.entity.Student;
import java.util.concurrent.CompletableFuture;

public interface EmailService {
    CompletableFuture<Void> sendRegistrationNotificationToAdmin(Student student);
    CompletableFuture<Void> sendApprovalNotificationToStudent(Student student);
}
