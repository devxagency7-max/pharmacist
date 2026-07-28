import '../../domain/entities/branch_entity.dart';

class PharmacyModel extends PharmacyEntity {
  PharmacyModel({
    required super.id,
    required super.name,
    super.logoUrl,
    required super.governorate,
    required super.address,
    super.workingHoursDescription,
    required super.isOpen,
    required super.ownerId,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
      governorate: json['governorate'] ?? '',
      address: json['address'] ?? '',
      workingHoursDescription: json['workingHoursDescription'],
      isOpen: json['isOpen'] ?? true,
      ownerId: json['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'governorate': governorate,
      'address': address,
      'workingHoursDescription': workingHoursDescription,
      'isOpen': isOpen,
      'ownerId': ownerId,
    };
  }
}

class BranchModel extends BranchEntity {
  BranchModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phoneNumber,
    required super.isMainBranch,
    super.latitude,
    super.longitude,
    required super.status,
    required super.pharmacyId,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isMainBranch: json['isMainBranch'] ?? false,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: json['status'] ?? 'Active',
      pharmacyId: json['pharmacyId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'isMainBranch': isMainBranch,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'pharmacyId': pharmacyId,
    };
  }
}
