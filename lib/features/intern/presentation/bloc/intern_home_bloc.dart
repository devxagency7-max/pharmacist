import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import '../../domain/entities/intern_draft_entity.dart';
import '../../domain/entities/intern_program_entity.dart';
import '../../domain/entities/intern_progress_entity.dart';
import '../../domain/entities/intern_supervisor_entity.dart';
import '../../domain/repositories/intern_repository.dart';
import 'intern_home_event.dart';
import 'intern_home_state.dart';

class InternHomeBloc extends Bloc<InternHomeEvent, InternHomeState> {
  final InternRepository _repository;

  InternHomeBloc(this._repository) : super(InternHomeInitial()) {
    on<InternHomeRequested>(_onHomeRequested);
    on<InternTrainingHoursLogSubmitted>(_onTrainingHoursLogSubmitted);
  }

  Future<void> _onHomeRequested(
    InternHomeRequested event,
    Emitter<InternHomeState> emit,
  ) async {
    emit(InternHomeLoading());
    try {
      final progressFuture = _repository.getProgress();
      final supervisorFuture = _repository.getMySupervisor();
      final programFuture = _repository.getMyProgram();
      final draftsFuture = _repository.getMyDrafts();

      final InternProgressEntity? progress = await progressFuture;
      final InternSupervisorEntity? supervisor = await supervisorFuture;
      final InternProgramEntity? program = await programFuture;
      final List<InternDraftEntity> drafts = await draftsFuture;

      emit(
        InternHomeLoaded(
          progress: progress,
          supervisor: supervisor,
          program: program,
          drafts: drafts,
        ),
      );
    } catch (e) {
      emit(InternHomeError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onTrainingHoursLogSubmitted(
    InternTrainingHoursLogSubmitted event,
    Emitter<InternHomeState> emit,
  ) async {
    final current = state;
    if (current is! InternHomeLoaded) return;

    emit(current.copyWith(isLoggingHours: true));
    try {
      await _repository.logTrainingHours(
        date: event.date,
        hours: event.hours,
        activityDescription: event.activityDescription,
      );
      add(InternHomeRequested());
    } catch (e) {
      emit(InternHomeError(mapErrorToMessage(e)));
    }
  }
}
