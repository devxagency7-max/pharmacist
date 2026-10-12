import '../../domain/entities/intern_draft_entity.dart';

class InternDraftModel extends InternDraftEntity {
  InternDraftModel({
    required super.draftId,
    required super.entityKind,
    required super.targetEntityId,
    required super.status,
    super.internClinicalNotes,
    super.supervisorFeedback,
    required super.createdAt,
    super.reviewedAt,
  });

  factory InternDraftModel.fromJson(Map<String, dynamic> json) {
    return InternDraftModel(
      draftId: json['draftId'] ?? '',
      entityKind: json['entityKind'] ?? '',
      targetEntityId: json['targetEntityId'] ?? '',
      status: json['status'] ?? 'PendingSupervisorReview',
      internClinicalNotes: json['internClinicalNotes'],
      supervisorFeedback: json['supervisorFeedback'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] ?? ''),
    );
  }
}
