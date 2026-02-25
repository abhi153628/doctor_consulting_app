import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? specialization,
    String? phoneNumber,
  });

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Real-time stream — emits true if admin blocks this user mid-session.
  Stream<bool> watchBlockedStatus();
}

// Simple Either class to avoid dartz dependency if not strictly needed,
// but dartz is common in clean arch. I'll use a simple version or add dartz.
// Let's add dartz to pubspec.yaml for easier development.
