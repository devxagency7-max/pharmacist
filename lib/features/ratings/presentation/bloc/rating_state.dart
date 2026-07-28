import '../../domain/entities/rating_entity.dart';

abstract class RatingState {}

class RatingInitial extends RatingState {}

class RatingLoading extends RatingState {}

class RatingLoaded extends RatingState {
  final List<RatingEntity> items;
  RatingLoaded(this.items);

  double get averageScore =>
      items.isEmpty ? 0 : items.map((r) => r.score).reduce((a, b) => a + b) / items.length;
}

class RatingError extends RatingState {
  final String message;
  RatingError(this.message);
}
