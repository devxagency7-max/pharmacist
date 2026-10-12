import '../../domain/entities/intern_progress_entity.dart';
import '../../domain/entities/intern_supervisor_entity.dart';
import '../../domain/entities/intern_program_entity.dart';
import '../../domain/entities/intern_draft_entity.dart';

abstract class InternHomeState {}

class InternHomeInitial extends InternHomeState {}

class InternHomeLoading extends InternHomeState {}

class InternHomeLoaded extends InternHomeState {
  // Null progress specifically means "no active assignment yet" — the
  // screen renders the full-screen "waiting on faculty" state for that,
  // per the backend's explicit instruction not to treat it as an error.
  final InternProgressEntity? progress;
  final InternSupervisorEntity? supervisor;
  final InternProgramEntity? program;
  final List<InternDraftEntity> drafts;
  final bool isLoggingHours;

  InternHomeLoaded({
    required this.progress,
    required this.supervisor,
    required this.program,
    required this.drafts,
    this.isLoggingHours = false,
  });

  InternHomeLoaded copyWith({bool? isLoggingHours}) {
    return InternHomeLoaded(
      progress: progress,
      supervisor: supervisor,
      program: program,
      drafts: drafts,
      isLoggingHours: isLoggingHours ?? this.isLoggingHours,
    );
  }
}

class InternHomeError extends InternHomeState {
  final String message;
  InternHomeError(this.message);
}
