import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_event.dart';
import 'rating_state.dart';

class RatingBloc extends Bloc<RatingEvent, RatingState> {
  final RatingRepository _repository;

  RatingBloc(this._repository) : super(RatingInitial()) {
    on<PharmacistRatingsRequested>(_onRatingsRequested);
  }

  Future<void> _onRatingsRequested(
    PharmacistRatingsRequested event,
    Emitter<RatingState> emit,
  ) async {
    emit(RatingLoading());
    try {
      final result = await _repository.getPharmacistRatings(event.pharmacistId);
      emit(RatingLoaded(result.items));
    } catch (e) {
      emit(RatingError(mapErrorToMessage(e)));
    }
  }
}
