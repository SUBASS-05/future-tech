package com.futuretech.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncEventDTO {
    private String eventId;     // Unique UUID
    private String eventType;   // e.g. STUDENT_APPROVED, PAYMENT_CREATED
    private String entityType;  // e.g. STUDENT, PAYMENT, ATTENDANCE, TASK, LEAVE
    private Long entityId;      // e.g. 101
    private String timestamp;   // ISO 8601 UTC string
    private Long version;
    private Map<String, Object> metadata;
}
