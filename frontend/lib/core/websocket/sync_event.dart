import 'dart:convert';

class SyncEvent {
  final String eventId;
  final String eventType;
  final String entityType;
  final dynamic entityId;
  final String timestamp;
  final int version;

  SyncEvent({
    required this.eventId,
    required this.eventType,
    required this.entityType,
    this.entityId,
    required this.timestamp,
    this.version = 1,
  });

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      eventId: json['eventId'] ?? '',
      eventType: json['eventType'] ?? '',
      entityType: json['entityType'] ?? '',
      entityId: json['entityId'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      version: json['version'] ?? 1,
    );
  }

  factory SyncEvent.fromRawJson(String rawJson) {
    return SyncEvent.fromJson(jsonDecode(rawJson));
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'entityType': entityType,
      'entityId': entityId,
      'timestamp': timestamp,
      'version': version,
    };
  }

  @override
  String toString() {
    return 'SyncEvent(eventId: $eventId, eventType: $eventType, entityType: $entityType, entityId: $entityId)';
  }
}
