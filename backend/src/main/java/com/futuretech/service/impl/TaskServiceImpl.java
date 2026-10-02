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
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TaskServiceImpl implements TaskService {
    private final TaskRepository taskRepository;
    private final TaskAssignmentRepository taskAssignmentRepository;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final com.futuretech.service.WebSocketEventPublisher eventPublisher;

    private String calculateStatus(TaskAssignment a) {
        if (a.getCompletedAt() != null) return "COMPLETED";
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        if (a.getExpiresAt() != null && !now.isBefore(a.getExpiresAt())) return "EXPIRED";
        if (a.getDueAt() != null && !now.isBefore(a.getDueAt())) return "OVERDUE";
        if (a.getStartedAt() != null) return "IN_PROGRESS";
        return "PENDING";
    }

    private boolean canComplete(TaskAssignment a) {
        if (a.getCompletedAt() != null) return false;
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        if (a.getExpiresAt() != null && !now.isBefore(a.getExpiresAt())) return false;
        if (a.getStartedAt() != null && a.getTask() != null && a.getTask().getEstimatedMinutes() != null && a.getTask().getEstimatedMinutes() > 0) {
            LocalDateTime minCompleteTime = a.getStartedAt().plusMinutes(a.getTask().getEstimatedMinutes());
            if (now.isBefore(minCompleteTime)) return false;
        }
        return true;
    }

    @Override
    @Transactional
    public MessageResponse createTask(String adminEmail, TaskRequest request) {
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new RuntimeException("Task title cannot be empty");
        }
        if (request.getDueAt() == null) {
            throw new RuntimeException("Due date cannot be null");
        }
        if (!request.getDueAt().isAfter(LocalDateTime.now(ZoneOffset.UTC))) {
            throw new RuntimeException("Due date must be in the future");
        }

        String title = request.getTitle().trim();

        if (request.getEstimatedMinutes() != null && request.getEstimatedMinutes() <= 0) {
            throw new RuntimeException("Estimated time must be a positive integer");
        }

        User admin = userRepository.findByEmail(adminEmail).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        TaskPriority priority = TaskPriority.MEDIUM;
        if (request.getPriority() != null) {
            try {
                priority = TaskPriority.valueOf(request.getPriority().toUpperCase());
            } catch (IllegalArgumentException e) {
                priority = TaskPriority.MEDIUM;
            }
        }
        
        Task task = Task.builder()
            .title(title)
            .description(request.getDescription())
            .priority(priority)
            .dueDate(request.getDueAt().toLocalDate())
            .dueTime(request.getDueAt().toLocalTime())
            .estimatedMinutes(request.getEstimatedMinutes())
            .createdBy(admin)
            .isActive(true)
            .build();
            
        task = taskRepository.save(task);

        if (request.getStudentIds() != null && !request.getStudentIds().isEmpty()) {
            List<Student> students = studentRepository.findAllById(request.getStudentIds());
            if (students.isEmpty()) {
                throw new RuntimeException("No valid students found for assignment");
            }
            
            final Task savedTask = task;
            LocalDateTime dueAt = request.getDueAt();
            LocalDateTime expiresAt = dueAt.plusHours(12);

            List<TaskAssignment> assignments = students.stream().map(student -> 
                TaskAssignment.builder()
                    .task(savedTask)
                    .student(student)
                    .status(TaskStatus.PENDING)
                    .assignedAt(LocalDateTime.now(ZoneOffset.UTC))
                    .dueAt(dueAt)
                    .expiresAt(expiresAt)
                    .build()
            ).collect(Collectors.toList());
            
            taskAssignmentRepository.saveAll(assignments);
            
            for (Student s : students) {
                if (s.getUser() != null && s.getUser().getEmail() != null) {
                    eventPublisher.publishToUser(s.getUser().getEmail(), "TASK_CREATED", "TASK", savedTask.getId());
                }
            }
            eventPublisher.publishToAdmin("TASK_CREATED", "TASK", savedTask.getId());
        } else {
            throw new RuntimeException("At least one student must be selected");
        }

        return new MessageResponse("Task created successfully");
    }

    @Override
    public List<TaskResponse> getAllTasks(String adminEmail) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        List<Task> tasks = taskRepository.findAll();
        
        return tasks.stream()
            .filter(task -> {
                List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(task.getId());
                return assignments.stream().anyMatch(a -> a.getExpiresAt() != null && a.getExpiresAt().isAfter(now));
            })
            .map(this::mapToTaskResponse)
            .collect(Collectors.toList());
    }

    @Override
    public List<TaskResponse> getTaskHistory(String adminEmail) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        List<Task> tasks = taskRepository.findAll();
        
        return tasks.stream()
            .filter(task -> {
                List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(task.getId());
                if (assignments.isEmpty()) return false;
                
                return assignments.stream().noneMatch(a -> a.getExpiresAt() != null && a.getExpiresAt().isAfter(now));
            })
            .map(this::mapToTaskResponse)
            .collect(Collectors.toList());
    }

    @Override
    public TaskResponse getTaskById(String adminEmail, Long taskId) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));
        return mapToTaskResponse(task);
    }

    private TaskResponse mapToTaskResponse(Task task) {
        List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(task.getId());
        int assignedCount = assignments.size();
        int completedCount = (int) assignments.stream()
            .filter(a -> a.getCompletedAt() != null)
            .count();
        
        LocalDateTime earliestDueAt = assignments.stream()
            .map(TaskAssignment::getDueAt)
            .filter(d -> d != null)
            .min(LocalDateTime::compareTo)
            .orElse(null);
            
        return TaskResponse.builder()
            .id(task.getId())
            .title(task.getTitle())
            .description(task.getDescription())
            .priority(task.getPriority().name())
            .dueDate(task.getDueDate())
            .dueTime(task.getDueTime())
            .dueAt(earliestDueAt)
            .estimatedMinutes(task.getEstimatedMinutes())
            .createdAt(task.getCreatedAt())
            .isActive(task.getIsActive())
            .assignedCount(assignedCount)
            .completedCount(completedCount)
            .build();
    }

    @Override
    @Transactional
    public MessageResponse updateTask(String adminEmail, Long taskId, TaskRequest request) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));
            
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new RuntimeException("Task title cannot be empty");
        }
        
        if (request.getEstimatedMinutes() != null && request.getEstimatedMinutes() <= 0) {
            throw new RuntimeException("Estimated time must be a positive integer");
        }
        
        task.setTitle(request.getTitle().trim());
        task.setDescription(request.getDescription());
        
        if (request.getPriority() != null) {
            try {
                task.setPriority(TaskPriority.valueOf(request.getPriority().toUpperCase()));
            } catch (IllegalArgumentException e) {
                // ignore invalid
            }
        }
        
        if (request.getDueAt() != null) {
            task.setDueDate(request.getDueAt().toLocalDate());
            task.setDueTime(request.getDueAt().toLocalTime());
            
            LocalDateTime expiresAt = request.getDueAt().plusHours(12);
            List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(taskId);
            for (TaskAssignment assignment : assignments) {
                assignment.setDueAt(request.getDueAt());
                assignment.setExpiresAt(expiresAt);
                taskAssignmentRepository.save(assignment);
            }
        }
        
        if (request.getEstimatedMinutes() != null) {
            task.setEstimatedMinutes(request.getEstimatedMinutes());
        }
        
        taskRepository.save(task);
        
        List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(taskId);
        for (TaskAssignment a : assignments) {
            if (a.getStudent() != null && a.getStudent().getUser() != null && a.getStudent().getUser().getEmail() != null) {
                eventPublisher.publishToUser(a.getStudent().getUser().getEmail(), "TASK_UPDATED", "TASK", taskId);
            }
        }
        eventPublisher.publishToAdmin("TASK_UPDATED", "TASK", taskId);
        
        return new MessageResponse("Task updated successfully");
    }

    @Override
    @Transactional
    public MessageResponse deleteTask(String adminEmail, Long taskId) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));
            
        List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(taskId);
        for (TaskAssignment a : assignments) {
            if (a.getStudent() != null && a.getStudent().getUser() != null && a.getStudent().getUser().getEmail() != null) {
                eventPublisher.publishToUser(a.getStudent().getUser().getEmail(), "TASK_DELETED", "TASK", taskId);
            }
        }
        eventPublisher.publishToAdmin("TASK_DELETED", "TASK", taskId);

        taskAssignmentRepository.deleteByTaskId(taskId);
        taskRepository.delete(task);
        return new MessageResponse("Task deleted successfully");
    }

    @Override
    @Transactional
    public MessageResponse assignStudents(String adminEmail, Long taskId, AssignStudentsRequest request) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));
            
        if (request.getStudentIds() == null || request.getStudentIds().isEmpty()) {
            throw new RuntimeException("At least one student must be selected");
        }
        
        List<Student> students = studentRepository.findAllById(request.getStudentIds());
        
        LocalDateTime dueAt = LocalDateTime.of(task.getDueDate(), task.getDueTime());
        LocalDateTime expiresAt = dueAt.plusHours(12);
        
        for (Student student : students) {
            boolean exists = taskAssignmentRepository.findByTaskIdAndStudentId(taskId, student.getId()).isPresent();
            if (!exists) {
                TaskAssignment assignment = TaskAssignment.builder()
                    .task(task)
                    .student(student)
                    .status(TaskStatus.PENDING)
                    .assignedAt(LocalDateTime.now(ZoneOffset.UTC))
                    .dueAt(dueAt)
                    .expiresAt(expiresAt)
                    .build();
                taskAssignmentRepository.save(assignment);
            }
        }
        
        return new MessageResponse("Students assigned successfully");
    }

    @Override
    @Transactional
    public MessageResponse removeAssignment(String adminEmail, Long taskId, Long studentId) {
        TaskAssignment assignment = taskAssignmentRepository.findByTaskIdAndStudentId(taskId, studentId)
            .orElseThrow(() -> new RuntimeException("Task assignment not found"));
            
        taskAssignmentRepository.delete(assignment);
        return new MessageResponse("Student assignment removed");
    }

    @Override
    public TaskProgressResponse getTaskProgress(String adminEmail, Long taskId) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found"));
            
        List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskId(taskId);
        
        int totalAssigned = assignments.size();
        int completed = 0;
        int inProgress = 0;
        int pending = 0;
        int overdue = 0;
        int expired = 0;
        
        List<StudentTaskProgressDTO> studentDTOs = assignments.stream().map(a -> {
            String status = calculateStatus(a);
            
            StudentTaskProgressDTO dto = StudentTaskProgressDTO.builder()
                .studentId(a.getStudent().getId())
                .studentName(a.getStudent().getFirstName() + " " + a.getStudent().getLastName())
                .studentRegistrationId(a.getStudent().getStudentCode())
                .status(status)
                .assignedAt(a.getAssignedAt())
                .startedAt(a.getStartedAt())
                .completedAt(a.getCompletedAt())
                .isOverdue(status.equals("OVERDUE") || status.equals("EXPIRED"))
                .dueAt(a.getDueAt())
                .expiresAt(a.getExpiresAt())
                .build();
                
            return dto;
        }).collect(Collectors.toList());
        
        for (StudentTaskProgressDTO s : studentDTOs) {
            if (s.getStatus().equals("COMPLETED")) {
                completed++;
            } else if (s.getStatus().equals("IN_PROGRESS")) {
                inProgress++;
            } else if (s.getStatus().equals("PENDING")) {
                pending++;
            } else if (s.getStatus().equals("OVERDUE")) {
                overdue++;
            } else if (s.getStatus().equals("EXPIRED")) {
                expired++;
            }
        }
        
        double percentage = totalAssigned > 0 ? (double) completed / totalAssigned * 100 : 0;
        
        return TaskProgressResponse.builder()
            .taskId(task.getId())
            .title(task.getTitle())
            .totalAssigned(totalAssigned)
            .completed(completed)
            .inProgress(inProgress)
            .pending(pending)
            .overdue(overdue)
            .expiredAssignments(expired)
            .completionPercentage(percentage)
            .completionRate(percentage)
            .students(studentDTOs)
            .build();
    }

    @Override
    public List<StudentTaskResponse> getStudentTasks(String studentEmail) {
        User user = userRepository.findByEmail(studentEmail).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        List<TaskAssignment> assignments = taskAssignmentRepository.findByStudentId(student.getId());
        
        return assignments.stream()
            .filter(a -> a.getCompletedAt() != null || (a.getExpiresAt() != null && a.getExpiresAt().isAfter(now)))
            .map(this::mapToStudentTaskResponse)
            .collect(Collectors.toList());
    }

    @Override
    public StudentTaskResponse getStudentTaskById(String studentEmail, Long taskId) {
        User user = userRepository.findByEmail(studentEmail).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        
        TaskAssignment assignment = taskAssignmentRepository.findByTaskIdAndStudentId(taskId, student.getId())
            .orElseThrow(() -> new RuntimeException("Task assignment not found"));
            
        return mapToStudentTaskResponse(assignment);
    }
    
    private StudentTaskResponse mapToStudentTaskResponse(TaskAssignment a) {
        Task task = a.getTask();
        String currentStatus = calculateStatus(a);
        return StudentTaskResponse.builder()
            .assignmentId(a.getId())
            .taskId(task.getId())
            .title(task.getTitle())
            .description(task.getDescription())
            .priority(task.getPriority().name())
            .dueDate(task.getDueDate())
            .dueTime(task.getDueTime())
            .dueAt(a.getDueAt())
            .expiresAt(a.getExpiresAt())
            .estimatedMinutes(task.getEstimatedMinutes())
            .status(currentStatus)
            .assignedAt(a.getAssignedAt())
            .startedAt(a.getStartedAt())
            .completedAt(a.getCompletedAt())
            .isOverdue(currentStatus.equals("OVERDUE") || currentStatus.equals("EXPIRED"))
            .canComplete(canComplete(a))
            .build();
    }

    @Override
    @Transactional
    public MessageResponse updateTaskStatus(String studentEmail, Long taskId, String status) {
        User user = userRepository.findByEmail(studentEmail).orElseThrow(() -> new RuntimeException("User not found"));
        Student student = studentRepository.findByUserId(user.getId()).orElseThrow(() -> new RuntimeException("Student not found"));
        
        TaskAssignment assignment = taskAssignmentRepository.findByTaskIdAndStudentId(taskId, student.getId())
                .orElseThrow(() -> new RuntimeException("Task assignment not found"));
                
        if (assignment.getExpiresAt() != null) {
            LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
            if (!now.isBefore(assignment.getExpiresAt())) {
                throw new RuntimeException("This task has expired and can no longer be completed.");
            }
        }
        
        if (assignment.getCompletedAt() != null) {
            throw new RuntimeException("This task is already completed.");
        }
        
        TaskStatus newStatus = TaskStatus.valueOf(status.toUpperCase());
        assignment.setStatus(newStatus);
        
        if (newStatus == TaskStatus.IN_PROGRESS && assignment.getStartedAt() == null) {
            assignment.setStartedAt(LocalDateTime.now(ZoneOffset.UTC));
        } else if (newStatus == TaskStatus.COMPLETED) {
            if (assignment.getStartedAt() == null) {
                throw new RuntimeException("Task must be started before completing.");
            }
            Integer estMins = assignment.getTask() != null ? assignment.getTask().getEstimatedMinutes() : null;
            if (estMins != null && estMins > 0) {
                LocalDateTime minCompleteTime = assignment.getStartedAt().plusMinutes(estMins);
                LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
                if (now.isBefore(minCompleteTime)) {
                    long remainingSeconds = java.time.Duration.between(now, minCompleteTime).getSeconds();
                    long mins = remainingSeconds / 60;
                    long secs = remainingSeconds % 60;
                    if (mins > 0) {
                        throw new RuntimeException(String.format("Estimated task duration is %d minutes. Please wait %d min %d sec before marking as complete.", estMins, mins, secs));
                    } else {
                        throw new RuntimeException(String.format("Estimated task duration is %d minutes. Please wait %d sec before marking as complete.", estMins, secs));
                    }
                }
            }
            assignment.setCompletedAt(LocalDateTime.now(ZoneOffset.UTC));
        }
        
        taskAssignmentRepository.save(assignment);
        
        eventPublisher.publishToUser(studentEmail, "TASK_STATUS_UPDATED", "TASK", taskId);
        eventPublisher.publishToAdmin("TASK_STATUS_UPDATED", "TASK", taskId);
        
        return new MessageResponse("Task status updated");
    }
}
