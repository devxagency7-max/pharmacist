import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
