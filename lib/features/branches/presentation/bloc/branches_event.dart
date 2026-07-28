abstract class BranchesEvent {}

class BranchesLoadList extends BranchesEvent {
  final String pharmacyId;
  BranchesLoadList(this.pharmacyId);
}

class BranchesCreateRequested extends BranchesEvent {
  final String pharmacyId;
  final String name;
  final String address;
  final String phoneNumber;
  final bool isMainBranch;
  final double? latitude;
  final double? longitude;

  BranchesCreateRequested({
    required this.pharmacyId,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.isMainBranch,
    this.latitude,
    this.longitude,
  });
}

class BranchesToggleStatusRequested extends BranchesEvent {
  final String pharmacyId;
  final String branchId;
  final String status;

  BranchesToggleStatusRequested({
    required this.pharmacyId,
    required this.branchId,
    required this.status,
  });
}

class PharmacyUpdateProfileRequested extends BranchesEvent {
  final String name;
  final String? logoUploadedFileId;
  final String governorate;
  final String address;
  final String? workingHoursDescription;
  final bool isOpen;

  PharmacyUpdateProfileRequested({
    required this.name,
    this.logoUploadedFileId,
    required this.governorate,
    required this.address,
    this.workingHoursDescription,
    required this.isOpen,
  });
}

class BranchesLoadGovernorates extends BranchesEvent {}
