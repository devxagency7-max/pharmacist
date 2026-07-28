import '../../domain/entities/user_entity.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthNeedsOnboarding extends AuthState {
  final UserEntity user;
  AuthNeedsOnboarding(this.user);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
