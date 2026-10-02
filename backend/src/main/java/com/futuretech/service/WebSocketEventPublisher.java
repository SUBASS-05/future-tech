package com.futuretech.service;

import com.futuretech.dto.SyncEventDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class WebSocketEventPublisher {
    private final SimpMessagingTemplate messagingTemplate;

    public void publishToUser(String email, String eventType, String entityType, Long entityId) {
        publishToUser(email, eventType, entityType, entityId, null);
    }

    public void publishToUser(String email, String eventType, String entityType, Long entityId, Map<String, Object> metadata) {
        if (email == null || email.trim().isEmpty()) return;
        SyncEventDTO event = buildEvent(eventType, entityType, entityId, metadata);
        executeAfterCommit(() -> {
            try {
                messagingTemplate.convertAndSendToUser(email.trim(), "/queue/updates", event);
                log.info("WebSocket event [{}] published to user [{}]: {}", eventType, email, event.getEventId());
            } catch (Exception e) {
                log.error("Failed to send WebSocket event [{}] to user [{}]: {}", eventType, email, e.getMessage());
            }
        });
    }

    public void publishToTopic(String topic, String eventType, String entityType, Long entityId) {
        publishToTopic(topic, eventType, entityType, entityId, null);
    }

    public void publishToTopic(String topic, String eventType, String entityType, Long entityId, Map<String, Object> metadata) {
        SyncEventDTO event = buildEvent(eventType, entityType, entityId, metadata);
        String destination = topic.startsWith("/") ? topic : "/topic/" + topic;
        executeAfterCommit(() -> {
            try {
                messagingTemplate.convertAndSend(destination, event);
                log.info("WebSocket event [{}] published to topic [{}]: {}", eventType, destination, event.getEventId());
            } catch (Exception e) {
                log.error("Failed to send WebSocket event [{}] to topic [{}]: {}", eventType, destination, e.getMessage());
            }
        });
    }

    public void publishToAdmin(String eventType, String entityType, Long entityId) {
        publishToTopic("/topic/admin", eventType, entityType, entityId, null);
    }

    public void publishToAdmin(String eventType, String entityType, Long entityId, Map<String, Object> metadata) {
        publishToTopic("/topic/admin", eventType, entityType, entityId, metadata);
    }

    private SyncEventDTO buildEvent(String eventType, String entityType, Long entityId, Map<String, Object> metadata) {
        return SyncEventDTO.builder()
                .eventId(UUID.randomUUID().toString())
                .eventType(eventType)
                .entityType(entityType)
                .entityId(entityId)
                .timestamp(Instant.now().toString())
                .version(1L)
                .metadata(metadata)
                .build();
    }

    private void executeAfterCommit(Runnable publishTask) {
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    publishTask.run();
                }
            });
        } else {
            publishTask.run();
        }
    }
}
