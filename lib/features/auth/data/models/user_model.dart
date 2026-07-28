import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.firebaseUid,
    required super.email,
    required super.name,
    required super.roles,
    required super.status,
    required super.isNewUser,
    super.pharmacyId,
    super.branchId,
    super.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      status: json['status'] ?? '',
      isNewUser: json['isNewUser'] ?? false,
      pharmacyId: json['pharmacyId'],
      branchId: json['branchId'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      'roles': roles,
      'status': status,
      'isNewUser': isNewUser,
      'pharmacyId': pharmacyId,
      'branchId': branchId,
      'phoneNumber': phoneNumber,
    };
  }
}
