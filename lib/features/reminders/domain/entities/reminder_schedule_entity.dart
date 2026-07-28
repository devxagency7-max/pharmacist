/// A patient reminder schedule, as managed by a pharmacist for one of their
/// Active-assigned patients (backend Module J: pharmacist reminder management).
class ReminderScheduleEntity {
  final String id;
  final String userId;
  final String type;
  final String? relatedEntityId;
  final String title;
  final String? description;
  final String frequencyType;
  final int? intervalHours;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isPaused;
  final DateTime? createdAt;

  ReminderScheduleEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.relatedEntityId,
    required this.title,
    this.description,
    required this.frequencyType,
    this.intervalHours,
    required this.startTime,
    this.endTime,
    required this.isPaused,
    this.createdAt,
  });

  factory ReminderScheduleEntity.fromJson(Map<String, dynamic> json) {
    return ReminderScheduleEntity(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'Other',
      relatedEntityId: json['relatedEntityId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      frequencyType: json['frequencyType'] as String? ?? 'Once',
      intervalHours: json['intervalHours'] as int?,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
      isPaused: json['isPaused'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
