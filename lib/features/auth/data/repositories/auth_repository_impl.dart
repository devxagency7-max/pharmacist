import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import 'package:pharmacist/features/devices/data/services/device_push_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/pharmacist_application_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/pharmacist_application_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final ApiClient _apiClient;
  final DevicePushService _devicePushService;

  AuthRepositoryImpl(this._firebaseAuth, this._apiClient, this._devicePushService);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required String displayName,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Firebase user displayName as fallback
      try {
        await credential.user?.updateDisplayName(name);
      } catch (e) {
        debugPrint('⚠️ Error updating Firebase display name: $e');
      }

      return await _syncUser(
        email: email,
        name: name,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    String? name,
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (name != null || displayName != null || phoneNumber != null) {
        return await _syncUser(
          email: email,
          name: name,
          displayName: displayName,
          phoneNumber: phoneNumber,
        );
      } else {
        return await _getProfile();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    debugPrint('==================================================');
    debugPrint('🔑 [GoogleSignIn] 1. Starting Google Sign-In flow...');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '886370477326-tcv4amt1iqd36nh278te98rafi30nd03.apps.googleusercontent.com',
      );
      debugPrint('🔑 [GoogleSignIn] 2. Cleaning previous session (signOut)...');
      await googleSignIn.signOut();

      debugPrint('🔑 [GoogleSignIn] 3. Launching Google Account Picker dialog...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ [GoogleSignIn] 3.1. User canceled account selection dialog.');
        throw Exception('تم إلغاء عملية التسجيل بواسطة Google');
      }

      debugPrint('✅ [GoogleSignIn] 4. Google Account Selected:');
      debugPrint('   - Email: ${googleUser.email}');
      debugPrint('   - Display Name: ${googleUser.displayName}');
      debugPrint('   - ID: ${googleUser.id}');
      debugPrint('   - Photo URL: ${googleUser.photoUrl}');

      debugPrint('🔑 [GoogleSignIn] 5. Requesting authentication tokens (ID Token & Access Token)...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('   - AccessToken present: ${googleAuth.accessToken != null}');
      debugPrint('   - IDToken present: ${googleAuth.idToken != null}');
      if (googleAuth.idToken != null) {
        debugPrint('   - IDToken prefix: ${googleAuth.idToken!.substring(0, (googleAuth.idToken!.length > 20 ? 20 : googleAuth.idToken!.length))}...');
      }

      debugPrint('🔑 [GoogleSignIn] 6. Creating Firebase OAuthCredential...');
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔑 [GoogleSignIn] 7. Authenticating with Firebase Auth using credential...');
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      debugPrint('✅ [GoogleSignIn] 8. Firebase Authentication Success:');
      debugPrint('   - Firebase UID: ${user?.uid}');
      debugPrint('   - Firebase Email: ${user?.email}');
      debugPrint('   - Firebase Phone: ${user?.phoneNumber}');
      debugPrint('   - Firebase Display Name: ${user?.displayName}');

      final String email = user?.email ?? googleUser.email;
      final String name = user?.displayName ?? googleUser.displayName ?? 'Pharmacist User';
      final String displayName = name.split(' ').first;

      debugPrint('🔑 [GoogleSignIn] 9. Syncing user with backend API (_syncUser)...');
      final syncedUser = await _syncUser(
        email: email,
        name: name,
        displayName: displayName,
        phoneNumber: user?.phoneNumber,
      );

      debugPrint('🎉 [GoogleSignIn] 10. Google Sign-In Flow Completed Successfully!');
      debugPrint('   - User ID: ${syncedUser.id}');
      debugPrint('   - User Name: ${syncedUser.name}');
      debugPrint('   - User Roles: ${syncedUser.roles}');
      debugPrint('==================================================');

      return syncedUser;
    } catch (e, stackTrace) {
      debugPrint('❌ [GoogleSignIn Exception]: $e');
      debugPrint('❌ [GoogleSignIn StackTrace]:\n$stackTrace');
      debugPrint('==================================================');
      rethrow;
    }
  }

  Future<UserEntity> _getProfile() async {
    final response = await _apiClient.dio.get(ApiConstants.usersMe);
    debugPrint('🔄 _getProfile API Raw Response: ${response.data}');
    return unwrapApiResponse(response, (json) => UserModel.fromJson(json));
  }

  Future<UserEntity> _syncUser({
    required String email,
    String? name,
    String? displayName,
    String? phoneNumber,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.syncUser,
      data: {
        'email': email,
        if (name != null) 'name': name,
        if (displayName != null) 'displayName': displayName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      },
    );

    debugPrint('🔄 _syncUser API Raw Response: ${response.data}');
    return unwrapApiResponse(response, (json) => UserModel.fromJson(json));
  }

  @override
  Future<void> completeProfile({required String name}) async {
    if (_firebaseAuth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _apiClient.dio.post(
      ApiConstants.completeProfile,
      data: {
        'name': name,
      },
    );
  }

  @override
  Future<UserEntity> updateProfile({
    String? name,
    String? phoneNumber,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (name != null) {
      await user.updateDisplayName(name);
    }

    return await _syncUser(
      email: user.email ?? '',
      name: name ?? user.displayName,
      displayName: name ?? user.displayName,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    // Force-refresh: a role change (e.g. admin approves a pharmacist/intern
    // application) only takes effect in a NEW ID token — the cached one
    // still carries the old role claims and would 403 on role-gated
    // endpoints instead of reflecting the promotion.
    await user.getIdToken(true);

    return await _getProfile();
  }

  @override
  Future<void> logout() async {
    await _devicePushService.unregisterCurrentDevice();
    await _firebaseAuth.signOut();
  }

  @override
  Future<PharmacistApplicationEntity> applyPharmacist({
    required String applicationType,
    String? licenseNumber,
    String? membershipNumber,
    String? universityName,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.pharmacistApply,
      data: {
        'applicationType': applicationType,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        if (membershipNumber != null) 'membershipNumber': membershipNumber,
        if (universityName != null) 'universityName': universityName,
      },
    );
    return unwrapApiResponse(
      response,
      (json) => PharmacistApplicationModel.fromJson(json),
    );
  }

  @override
  Future<PharmacistApplicationEntity> applyAsIntern({
    required String universityId,
    required String facultyId,
    String? membershipNumber,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.internApply,
      data: {
        'universityId': universityId,
        'facultyId': facultyId,
        if (membershipNumber != null) 'membershipNumber': membershipNumber,
        'universityName': null,
      },
    );
    return unwrapApiResponse(
      response,
      (json) => PharmacistApplicationModel.fromJson(json),
    );
  }

  @override
  Future<PharmacistApplicationEntity?> getApplicationStatus() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.pharmacistApplicationStatus,
      );
      return unwrapApiResponse(
        response,
        (json) => PharmacistApplicationModel.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> withdrawApplication(String applicationId) async {
    await _apiClient.dio.delete(
      ApiConstants.pharmacistWithdraw(applicationId),
    );
  }

  @override
  Future<void> uploadDocument({
    required String applicationId,
    required String documentType,
    required String uploadedFileId,
    String? originalFileName,
    String? mimeType,
    int? fileSizeBytes,
  }) async {
    await _apiClient.dio.post(
      ApiConstants.pharmacistDocuments(applicationId),
      data: {
        'documentType': documentType,
        'uploadedFileId': uploadedFileId,
        if (originalFileName != null) 'originalFileName': originalFileName,
        if (mimeType != null) 'mimeType': mimeType,
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      },
    );
  }
}
