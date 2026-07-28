import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<CompleteProfileSubmitted>(_onCompleteProfileSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthDebugOverrideRoles>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        final updatedUser = currentState.user.copyWith(
          roles: event.roles,
          pharmacyId: event.pharmacyId,
          branchId: event.branchId,
        );
        emit(AuthAuthenticated(updatedUser));
      }
    });
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<ProfileUpdateSubmitted>(_onProfileUpdateSubmitted);
  }

  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      // Keep existing state or do nothing on refresh failure
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpSubmitted(SignUpSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        displayName: event.displayName,
        phoneNumber: event.phoneNumber,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCompleteProfileSubmitted(CompleteProfileSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.completeProfile(name: event.name);
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onProfileUpdateSubmitted(
    ProfileUpdateSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.updateProfile(
        name: event.name,
        phoneNumber: event.phoneNumber,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
