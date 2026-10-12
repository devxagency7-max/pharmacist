import '../entities/user_entity.dart';
import '../entities/pharmacist_application_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required String displayName,
    required String phoneNumber,
  });

  Future<UserEntity> login({
    required String email,
    required String password,
    String? name,
    String? displayName,
    String? phoneNumber,
  });

  Future<UserEntity> signInWithGoogle();

  Future<void> completeProfile({
    required String name,
  });

  Future<UserEntity> updateProfile({
    String? name,
    String? phoneNumber,
  });

  Future<UserEntity?> getCurrentUser();
  Future<void> logout();

  Future<PharmacistApplicationEntity> applyPharmacist({
    required String applicationType,
    String? licenseNumber,
    String? membershipNumber,
    String? universityName,
  });

  /// POST /intern/apply — cleaner, Intern-specific alias of [applyPharmacist]
  /// with `applicationType: "Intern"` baked in server-side. Requires real
  /// university/faculty ids from the academic pickers, not free text.
  Future<PharmacistApplicationEntity> applyAsIntern({
    required String universityId,
    required String facultyId,
    String? membershipNumber,
  });

  Future<PharmacistApplicationEntity?> getApplicationStatus();

  Future<void> withdrawApplication(String applicationId);

  Future<void> uploadDocument({
    required String applicationId,
    required String documentType,
    required String uploadedFileId,
    String? originalFileName,
    String? mimeType,
    int? fileSizeBytes,
  });
}
