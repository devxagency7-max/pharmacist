class UserEntity {
  final String id;
  final String firebaseUid;
  final String email;
  final String name;
  final List<String> roles;
  final String status;
  final bool isNewUser;
  final String? pharmacyId;
  final String? branchId;
  final String? phoneNumber;

  UserEntity({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.roles,
    required this.status,
    required this.isNewUser,
    this.pharmacyId,
    this.branchId,
    this.phoneNumber,
  });

  UserEntity copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? name,
    List<String>? roles,
    String? status,
    bool? isNewUser,
    String? pharmacyId,
    String? branchId,
    String? phoneNumber,
  }) {
    return UserEntity(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      isNewUser: isNewUser ?? this.isNewUser,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      branchId: branchId ?? this.branchId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
