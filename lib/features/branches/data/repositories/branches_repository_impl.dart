import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/branches_repository.dart';
import '../models/branch_model.dart';

class BranchesRepositoryImpl implements BranchesRepository {
  final ApiClient _apiClient;

  BranchesRepositoryImpl(this._apiClient);

  @override
  Future<PharmacyEntity> updatePharmacyProfile({
    required String name,
    String? logoUploadedFileId,
    required String governorate,
    required String address,
    String? workingHoursDescription,
    required bool isOpen,
  }) async {
    final response = await _apiClient.dio.put(
      ApiConstants.updatePharmacyProfile,
      data: {
        'name': name,
        if (logoUploadedFileId != null) 'logoUploadedFileId': logoUploadedFileId,
        'governorate': governorate,
        'address': address,
        if (workingHoursDescription != null) 'workingHoursDescription': workingHoursDescription,
        'isOpen': isOpen,
      },
    );
    return unwrapApiResponse(response, (json) => PharmacyModel.fromJson(json));
  }

  @override
  Future<List<BranchEntity>> getBranches({required String pharmacyId}) async {
    final response = await _apiClient.dio.get(
      ApiConstants.pharmacyBranches(pharmacyId),
    );
    final list = unwrapApiResponse(response, (json) => json as List);
    return list.map((item) => BranchModel.fromJson(item)).toList();
  }

  @override
  Future<BranchEntity> addBranch({
    required String pharmacyId,
    required String name,
    required String address,
    required String phoneNumber,
    required bool isMainBranch,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.pharmacyBranches(pharmacyId),
      data: {
        'name': name,
        'address': address,
        'phoneNumber': phoneNumber,
        'isMainBranch': isMainBranch,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return unwrapApiResponse(response, (json) => BranchModel.fromJson(json));
  }

  @override
  Future<void> setBranchStatus({
    required String branchId,
    required String status,
  }) async {
    await _apiClient.dio.put(
      '/pharmacies/branches/$branchId/status',
      data: {
        'status': status,
      },
    );
  }

  @override
  Future<List<String>> getGovernorates() async {
    final response = await _apiClient.dio.get(
      ApiConstants.getGovernorates,
    );
    final list = unwrapApiResponse(response, (json) => json as List);
    return list.map((item) => item.toString()).toList();
  }
}
