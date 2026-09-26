package com.futuretech.service;
import com.futuretech.dto.*;
import com.futuretech.entity.Task;
import com.futuretech.entity.StudentTask;
import java.util.List;
public interface TaskService {
    MessageResponse createTask(String adminEmail, TaskRequest request);
    List<StudentTask> getStudentTasks(String studentEmail);
    MessageResponse updateTaskStatus(String studentEmail, Long taskId, String status);
}
