import '../../domain/entities/rating_entity.dart';

class RatingModel extends RatingEntity {
  RatingModel({
    required super.id,
    required super.reviewerId,
    required super.reviewerName,
    required super.score,
    super.comment,
    required super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      reviewerId: json['reviewerId'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
