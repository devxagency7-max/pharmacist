class PharmacyEntity {
  final String id;
  final String name;
  final String? logoUrl;
  final String governorate;
  final String address;
  final String? workingHoursDescription;
  final bool isOpen;
  final String ownerId;

  PharmacyEntity({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.governorate,
    required this.address,
    this.workingHoursDescription,
    required this.isOpen,
    required this.ownerId,
  });
}

class BranchEntity {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final bool isMainBranch;
  final double? latitude;
  final double? longitude;
  final String status; // Active, Inactive
  final String pharmacyId;

  BranchEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.isMainBranch,
    this.latitude,
    this.longitude,
    required this.status,
    required this.pharmacyId,
  });
}
