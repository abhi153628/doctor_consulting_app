import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent(this.email, this.password);
}

class AuthSignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? specialization;
  final String? phoneNumber;
  const AuthSignUpEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.specialization,
    this.phoneNumber,
  });
}

class AuthLogoutEvent extends AuthEvent {}

class AuthCheckStatusEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthSignUpEvent>(_onSignUp);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthCheckStatusEvent>(_onCheckStatus);
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onSignUp(AuthSignUpEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final result = await authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
        specialization: event.specialization,
        phoneNumber: event.phoneNumber,
      );
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final result = await authRepository.getCurrentUser();
      result.fold(
        (_) => emit(AuthUnauthenticated()),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}
