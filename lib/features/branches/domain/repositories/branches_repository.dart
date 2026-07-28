import '../entities/branch_entity.dart';

abstract class BranchesRepository {
  Future<PharmacyEntity> updatePharmacyProfile({
    required String name,
    String? logoUploadedFileId,
    required String governorate,
    required String address,
    String? workingHoursDescription,
    required bool isOpen,
  });

  Future<List<BranchEntity>> getBranches({
    required String pharmacyId,
  });

  Future<BranchEntity> addBranch({
    required String pharmacyId,
    required String name,
    required String address,
    required String phoneNumber,
    required bool isMainBranch,
    double? latitude,
    double? longitude,
  });

  Future<void> setBranchStatus({
    required String branchId,
    required String status,
  });

  Future<List<String>> getGovernorates();
}
