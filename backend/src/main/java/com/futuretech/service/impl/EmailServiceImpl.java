package com.futuretech.service.impl;
import com.futuretech.entity.EmailLog;
import com.futuretech.entity.Student;
import com.futuretech.entity.enums.EmailStatus;
import com.futuretech.entity.enums.EmailType;
import com.futuretech.repository.EmailLogRepository;
import com.futuretech.service.EmailService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
public class EmailServiceImpl implements EmailService {

    private final EmailLogRepository emailLogRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${resend.api.key:re_placeholder_key}")
    private String resendApiKey;

    @Value("${app.admin.email:admin@futuretech.com}")
    private String adminEmail;

    private static final String RESEND_API_URL = "https://api.resend.com/emails";
    private static final String SENDER_EMAIL = "onboarding@resend.dev";

    @Override
    @Async
    public CompletableFuture<Void> sendRegistrationNotificationToAdmin(Student student) {
        String subject = "New Student Registration: " + student.getFirstName();
        String htmlContent = "<h1>New Student Registration</h1>" +
                "<p>A new student has registered and is pending approval.</p>" +
                "<p><strong>Name:</strong> " + student.getFirstName() + " " + (student.getLastName() != null ? student.getLastName() : "") + "</p>" +
                "<p><strong>Email:</strong> " + student.getUser().getEmail() + "</p>" +
                "<p><strong>Student Code:</strong> " + student.getStudentCode() + "</p>";

        sendEmail(adminEmail, subject, htmlContent, student, EmailType.STUDENT_REGISTRATION);
        return CompletableFuture.completedFuture(null);
    }

    @Override
    @Async
    public CompletableFuture<Void> sendApprovalNotificationToStudent(Student student) {
        String subject = "Future Tech - Account Approved";
        String htmlContent = "<h1>Account Approved</h1>" +
                "<p>Hello " + student.getFirstName() + ",</p>" +
                "<p>Your registration at Future Tech has been approved by the admin.</p>" +
                "<p>You can now log in to the mobile application and complete your profile.</p>";

        sendEmail(student.getUser().getEmail(), subject, htmlContent, student, EmailType.STUDENT_APPROVAL);
        return CompletableFuture.completedFuture(null);
    }

    private void sendEmail(String to, String subject, String htmlContent, Student student, EmailType emailType) {
        EmailLog emailLog = EmailLog.builder()
                .student(student)
                .email(to)
                .subject(subject)
                .emailType(emailType)
                .status(EmailStatus.PENDING)
                .build();
        emailLog = emailLogRepository.save(emailLog);

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(resendApiKey);

            Map<String, Object> body = new HashMap<>();
            body.put("from", "Future Tech <" + SENDER_EMAIL + ">");
            body.put("to", new String[]{to});
            body.put("subject", subject);
            body.put("html", htmlContent);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(RESEND_API_URL, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                emailLog.setStatus(EmailStatus.SENT);
                emailLog.setSentAt(LocalDateTime.now());
            } else {
                emailLog.setStatus(EmailStatus.FAILED);
                emailLog.setErrorMessage(response.getBody());
            }
        } catch (Exception e) {
            emailLog.setStatus(EmailStatus.FAILED);
            emailLog.setErrorMessage(e.getMessage());
        } finally {
            emailLogRepository.save(emailLog);
        }
    }
}
