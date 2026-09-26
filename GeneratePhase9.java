import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

public class GeneratePhase9 {
    public static void main(String[] args) throws Exception {
        String basePath = "d:/future tech/backend/src/main/java/com/futuretech";

        Map<String, String> files = new HashMap<>();

        // ---- EmailService ----
        files.put(basePath + "/service/EmailService.java",
            "package com.futuretech.service;\n" +
            "import com.futuretech.entity.Student;\n" +
            "import java.util.concurrent.CompletableFuture;\n\n" +
            "public interface EmailService {\n" +
            "    CompletableFuture<Void> sendRegistrationNotificationToAdmin(Student student);\n" +
            "    CompletableFuture<Void> sendApprovalNotificationToStudent(Student student);\n" +
            "}\n"
        );

        // ---- EmailServiceImpl ----
        files.put(basePath + "/service/impl/EmailServiceImpl.java",
            "package com.futuretech.service.impl;\n" +
            "import com.futuretech.entity.EmailLog;\n" +
            "import com.futuretech.entity.Student;\n" +
            "import com.futuretech.entity.enums.EmailStatus;\n" +
            "import com.futuretech.entity.enums.EmailType;\n" +
            "import com.futuretech.repository.EmailLogRepository;\n" +
            "import com.futuretech.service.EmailService;\n" +
            "import lombok.RequiredArgsConstructor;\n" +
            "import org.springframework.beans.factory.annotation.Value;\n" +
            "import org.springframework.http.HttpEntity;\n" +
            "import org.springframework.http.HttpHeaders;\n" +
            "import org.springframework.http.MediaType;\n" +
            "import org.springframework.http.ResponseEntity;\n" +
            "import org.springframework.scheduling.annotation.Async;\n" +
            "import org.springframework.stereotype.Service;\n" +
            "import org.springframework.web.client.RestTemplate;\n" +
            "import java.time.LocalDateTime;\n" +
            "import java.util.HashMap;\n" +
            "import java.util.Map;\n" +
            "import java.util.concurrent.CompletableFuture;\n\n" +
            "@Service\n" +
            "@RequiredArgsConstructor\n" +
            "public class EmailServiceImpl implements EmailService {\n\n" +
            "    private final EmailLogRepository emailLogRepository;\n" +
            "    private final RestTemplate restTemplate = new RestTemplate();\n\n" +
            "    @Value(\"${resend.api.key:re_placeholder_key}\")\n" +
            "    private String resendApiKey;\n\n" +
            "    @Value(\"${app.admin.email:admin@futuretech.com}\")\n" +
            "    private String adminEmail;\n\n" +
            "    private static final String RESEND_API_URL = \"https://api.resend.com/emails\";\n" +
            "    private static final String SENDER_EMAIL = \"onboarding@resend.dev\";\n\n" +
            "    @Override\n" +
            "    @Async\n" +
            "    public CompletableFuture<Void> sendRegistrationNotificationToAdmin(Student student) {\n" +
            "        String subject = \"New Student Registration: \" + student.getFirstName();\n" +
            "        String htmlContent = \"<h1>New Student Registration</h1>\" +\n" +
            "                \"<p>A new student has registered and is pending approval.</p>\" +\n" +
            "                \"<p><strong>Name:</strong> \" + student.getFirstName() + \" \" + (student.getLastName() != null ? student.getLastName() : \"\") + \"</p>\" +\n" +
            "                \"<p><strong>Email:</strong> \" + student.getUser().getEmail() + \"</p>\" +\n" +
            "                \"<p><strong>Student Code:</strong> \" + student.getStudentCode() + \"</p>\";\n\n" +
            "        sendEmail(adminEmail, subject, htmlContent, student, EmailType.STUDENT_REGISTRATION);\n" +
            "        return CompletableFuture.completedFuture(null);\n" +
            "    }\n\n" +
            "    @Override\n" +
            "    @Async\n" +
            "    public CompletableFuture<Void> sendApprovalNotificationToStudent(Student student) {\n" +
            "        String subject = \"Future Tech - Account Approved\";\n" +
            "        String htmlContent = \"<h1>Account Approved</h1>\" +\n" +
            "                \"<p>Hello \" + student.getFirstName() + \",</p>\" +\n" +
            "                \"<p>Your registration at Future Tech has been approved by the admin.</p>\" +\n" +
            "                \"<p>You can now log in to the mobile application and complete your profile.</p>\";\n\n" +
            "        sendEmail(student.getUser().getEmail(), subject, htmlContent, student, EmailType.STUDENT_APPROVAL);\n" +
            "        return CompletableFuture.completedFuture(null);\n" +
            "    }\n\n" +
            "    private void sendEmail(String to, String subject, String htmlContent, Student student, EmailType emailType) {\n" +
            "        EmailLog emailLog = EmailLog.builder()\n" +
            "                .student(student)\n" +
            "                .email(to)\n" +
            "                .subject(subject)\n" +
            "                .emailType(emailType)\n" +
            "                .status(EmailStatus.PENDING)\n" +
            "                .build();\n" +
            "        emailLog = emailLogRepository.save(emailLog);\n\n" +
            "        try {\n" +
            "            HttpHeaders headers = new HttpHeaders();\n" +
            "            headers.setContentType(MediaType.APPLICATION_JSON);\n" +
            "            headers.setBearerAuth(resendApiKey);\n\n" +
            "            Map<String, Object> body = new HashMap<>();\n" +
            "            body.put(\"from\", \"Future Tech <\" + SENDER_EMAIL + \">\");\n" +
            "            body.put(\"to\", new String[]{to});\n" +
            "            body.put(\"subject\", subject);\n" +
            "            body.put(\"html\", htmlContent);\n\n" +
            "            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);\n" +
            "            ResponseEntity<String> response = restTemplate.postForEntity(RESEND_API_URL, request, String.class);\n\n" +
            "            if (response.getStatusCode().is2xxSuccessful()) {\n" +
            "                emailLog.setStatus(EmailStatus.SENT);\n" +
            "                emailLog.setSentAt(LocalDateTime.now());\n" +
            "            } else {\n" +
            "                emailLog.setStatus(EmailStatus.FAILED);\n" +
            "                emailLog.setErrorMessage(response.getBody());\n" +
            "            }\n" +
            "        } catch (Exception e) {\n" +
            "            emailLog.setStatus(EmailStatus.FAILED);\n" +
            "            emailLog.setErrorMessage(e.getMessage());\n" +
            "        } finally {\n" +
            "            emailLogRepository.save(emailLog);\n" +
            "        }\n" +
            "    }\n" +
            "}\n"
        );

        // Write files
        for (Map.Entry<String, String> entry : files.entrySet()) {
            File file = new File(entry.getKey());
            file.getParentFile().mkdirs();
            Files.write(Paths.get(entry.getKey()), entry.getValue().getBytes());
            System.out.println("Generated: " + entry.getKey());
        }

        // Update AuthServiceImpl
        String authServicePath = basePath + "/service/impl/AuthServiceImpl.java";
        String authServiceContent = new String(Files.readAllBytes(Paths.get(authServicePath)));
        if (!authServiceContent.contains("EmailService emailService")) {
            authServiceContent = authServiceContent.replace(
                "import com.futuretech.service.AuthService;",
                "import com.futuretech.service.AuthService;\nimport com.futuretech.service.EmailService;"
            );
            authServiceContent = authServiceContent.replace(
                "private final UserDetailsService userDetailsService;",
                "private final UserDetailsService userDetailsService;\n    private final EmailService emailService;"
            );
            authServiceContent = authServiceContent.replace(
                "// TODO: Send Email (Phase 9)",
                "emailService.sendRegistrationNotificationToAdmin(student);"
            );
            Files.write(Paths.get(authServicePath), authServiceContent.getBytes());
            System.out.println("Updated: " + authServicePath);
        }

        // Update AdminServiceImpl
        String adminServicePath = basePath + "/service/impl/AdminServiceImpl.java";
        String adminServiceContent = new String(Files.readAllBytes(Paths.get(adminServicePath)));
        if (!adminServiceContent.contains("EmailService emailService")) {
            adminServiceContent = adminServiceContent.replace(
                "import com.futuretech.service.AdminService;",
                "import com.futuretech.service.AdminService;\nimport com.futuretech.service.EmailService;"
            );
            adminServiceContent = adminServiceContent.replace(
                "private final StudentRepository studentRepository;",
                "private final StudentRepository studentRepository;\n    private final EmailService emailService;"
            );
            adminServiceContent = adminServiceContent.replace(
                "// TODO: Send Approval Email (Phase 9)",
                "emailService.sendApprovalNotificationToStudent(student);"
            );
            Files.write(Paths.get(adminServicePath), adminServiceContent.getBytes());
            System.out.println("Updated: " + adminServicePath);
        }
        
        System.out.println("Phase 9 Generation Complete!");
    }
}
