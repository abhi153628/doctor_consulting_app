import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String email, String password) {
    return repository.login(email: email, password: password);
  }
}

class SignUpUseCase {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? specialization,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
      specialization: specialization,
    );
  }
}

// etc...
