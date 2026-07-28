abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
}

class SignUpSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String displayName;
  final String phoneNumber;

  SignUpSubmitted({
    required this.email,
    required this.password,
    required this.name,
    required this.displayName,
    required this.phoneNumber,
  });
}

class CompleteProfileSubmitted extends AuthEvent {
  final String name;
  CompleteProfileSubmitted({required this.name});
}

class ProfileUpdateSubmitted extends AuthEvent {
  final String? name;
  final String? phoneNumber;
  ProfileUpdateSubmitted({this.name, this.phoneNumber});
}

class LogoutRequested extends AuthEvent {}

class AuthDebugOverrideRoles extends AuthEvent {
  final List<String> roles;
  final String pharmacyId;
  final String branchId;
  AuthDebugOverrideRoles({required this.roles, required this.pharmacyId, required this.branchId});
}

class AuthRefreshRequested extends AuthEvent {}
