import 'dart:async';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/file_upload_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Maps a `documentType` (Step 2 of the upload flow) to the `fileType` the
/// backend's `POST /api/files/upload` expects (Step 1). No dedicated
/// `FileType` value exists for university certificates or internship cards,
/// so those fall back to `Other`.
const Map<String, String> _documentTypeToFileType = {
  'NationalIdFront': 'Identification',
  'NationalIdBack': 'Identification',
  'PharmacyLicense': 'License',
  'UniversityCertificate': 'Other',
  'InternshipCard': 'Other',
};

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final AuthRepository _authRepository;
  final FileUploadService _fileUploadService;

  OnboardingBloc(this._authRepository, this._fileUploadService) : super(OnboardingInitial()) {
    on<OnboardingCheckStatus>(_onCheckStatus);
    on<OnboardingSubmitApplication>(_onSubmitApplication);
    on<OnboardingUploadDoc>(_onUploadDoc);
    on<OnboardingSimulateApproval>(_onSimulateApproval);
  }

  Future<void> _onCheckStatus(
    OnboardingCheckStatus event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final app = await _authRepository.getApplicationStatus();
      if (app == null) {
        emit(OnboardingNoApplication());
      } else {
        emit(OnboardingApplied(
          application: app,
          uploadProgress: const {},
          uploadedUrls: const {},
        ));
      }
    } catch (e) {
      emit(OnboardingError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onSubmitApplication(
    OnboardingSubmitApplication event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final app = await _authRepository.applyPharmacist(
        applicationType: event.applicationType,
        licenseNumber: event.licenseNumber,
        membershipNumber: event.membershipNumber,
        universityName: event.universityName,
      );
      emit(OnboardingApplied(
        application: app,
        uploadProgress: const {},
        uploadedUrls: const {},
      ));
    } catch (e) {
      emit(OnboardingError(mapErrorToMessage(e)));
    }
  }

  Future<void> _onUploadDoc(
    OnboardingUploadDoc event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OnboardingApplied) return;

    final updatedProgress = Map<String, double>.from(currentState.uploadProgress);
    final updatedUrls = Map<String, String>.from(currentState.uploadedUrls);

    updatedProgress[event.documentType] = 0.1;
    emit(currentState.copyWith(uploadProgress: updatedProgress));

    try {
      final fileType = _documentTypeToFileType[event.documentType] ?? 'Other';
      final uploaded = await _fileUploadService.uploadFile(
        filePath: event.filePath,
        fileType: fileType,
      );
      updatedProgress[event.documentType] = 0.9;
      emit(currentState.copyWith(uploadProgress: updatedProgress));

      final file = File(event.filePath);
      await _authRepository.uploadDocument(
        applicationId: event.applicationId,
        documentType: event.documentType,
        uploadedFileId: uploaded.id,
        originalFileName: event.filePath.split(RegExp(r'[\\/]')).last,
        fileSizeBytes: await file.length(),
      );

      updatedProgress[event.documentType] = 1.0;
      updatedUrls[event.documentType] = uploaded.url;
      emit(currentState.copyWith(uploadProgress: updatedProgress, uploadedUrls: updatedUrls));
    } catch (e) {
      updatedProgress[event.documentType] = 0.0;
      emit(currentState.copyWith(uploadProgress: updatedProgress));
      emit(OnboardingError('فشل رفع المستند: ${mapErrorToMessage(e)}'));
      // Restore previous state without error
      emit(currentState.copyWith(uploadProgress: updatedProgress));
    }
  }

  void _onSimulateApproval(
    OnboardingSimulateApproval event,
    Emitter<OnboardingState> emit,
  ) {
    emit(OnboardingSuccess());
  }
}
