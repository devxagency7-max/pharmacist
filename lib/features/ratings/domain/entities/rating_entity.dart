class RatingEntity {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final int score;
  final String? comment;
  final DateTime createdAt;

  RatingEntity({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.score,
    this.comment,
    required this.createdAt,
  });
}
