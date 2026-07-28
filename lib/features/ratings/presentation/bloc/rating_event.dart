abstract class RatingEvent {}

class PharmacistRatingsRequested extends RatingEvent {
  final String pharmacistId;
  PharmacistRatingsRequested(this.pharmacistId);
}
