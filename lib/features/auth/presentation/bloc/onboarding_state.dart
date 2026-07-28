import '../../domain/entities/pharmacist_application_entity.dart';

abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingNoApplication extends OnboardingState {}

class OnboardingApplied extends OnboardingState {
  final PharmacistApplicationEntity application;
  final Map<String, double> uploadProgress;
  final Map<String, String> uploadedUrls;

  OnboardingApplied({
    required this.application,
    required this.uploadProgress,
    required this.uploadedUrls,
  });

  OnboardingApplied copyWith({
    PharmacistApplicationEntity? application,
    Map<String, double>? uploadProgress,
    Map<String, String>? uploadedUrls,
  }) {
    return OnboardingApplied(
      application: application ?? this.application,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
    );
  }
}

class OnboardingSuccess extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError(this.message);
}
