package com.futuretech.service.impl;
import com.futuretech.dto.*;
import com.futuretech.entity.*;
import com.futuretech.entity.enums.*;
import com.futuretech.repository.*;
import com.futuretech.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
@Service
@RequiredArgsConstructor
public class TaskServiceImpl implements TaskService {
    private final TaskRepository taskRepository;
    private final TaskTargetRepository targetRepository;
    private final StudentTaskRepository studentTaskRepository;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;

    @Override
    @Transactional
    public MessageResponse createTask(String adminEmail, TaskRequest request) {
        User admin = userRepository.findByEmail(adminEmail).orElseThrow();
        Task task = Task.builder()
            .title(request.getTitle())
            .description(request.getDescription())
            .dueDate(request.getDueDate())
            .createdDate(LocalDate.now())
            .createdBy(admin)
            .build();
        task = taskRepository.save(task);

        TaskTarget target = TaskTarget.builder()
            .task(task)
            .targetType(TargetType.valueOf(request.getTargetType()))
            .academicBatch(request.getAcademicBatch())
            .build();
        targetRepository.save(target);

        // In a real scenario, we'd find all students matching the target and create StudentTask records here.
        // Simplified for this scaffolding block.
        return new MessageResponse("Task created successfully");
    }

    @Override
    public List<StudentTask> getStudentTasks(String studentEmail) {
        User user = userRepository.findByEmail(studentEmail).orElseThrow();
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow();
        return studentTaskRepository.findByStudentId(student.getId());
    }

    @Override
    @Transactional
    public MessageResponse updateTaskStatus(String studentEmail, Long taskId, String status) {
        User user = userRepository.findByEmail(studentEmail).orElseThrow();
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow();
        
        StudentTask st = studentTaskRepository.findByStudentId(student.getId())
                .stream().filter(t -> t.getTask().getId().equals(taskId)).findFirst()
                .orElseThrow(() -> new RuntimeException("Task not found for student"));
                
        st.setStatus(TaskStatus.valueOf(status));
        if (TaskStatus.COMPLETED.name().equals(status)) {
            st.setCompletedAt(LocalDateTime.now());
        }
        studentTaskRepository.save(st);
        return new MessageResponse("Task status updated");
    }
}
