abstract class OnboardingEvent {}

class OnboardingCheckStatus extends OnboardingEvent {}

class OnboardingSubmitApplication extends OnboardingEvent {
  final String applicationType;
  final String? licenseNumber;
  final String? membershipNumber;
  final String? universityName;

  OnboardingSubmitApplication({
    required this.applicationType,
    this.licenseNumber,
    this.membershipNumber,
    this.universityName,
  });
}

class OnboardingUploadDoc extends OnboardingEvent {
  final String applicationId;
  final String documentType;
  final String filePath; // Local path to upload (simulated)

  OnboardingUploadDoc({
    required this.applicationId,
    required this.documentType,
    required this.filePath,
  });
}

class OnboardingSimulateApproval extends OnboardingEvent {}
