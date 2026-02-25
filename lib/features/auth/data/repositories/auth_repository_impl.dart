import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctor_booking_app/features/auth/data/datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? specialization,
    String? phoneNumber,
  }) async {
    try {
      final userEntity = await remoteDataSource.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        specialization: specialization,
        phoneNumber: phoneNumber,
      );
      return Right(userEntity);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseErrorMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userEntity = await remoteDataSource.login(email, password);
      return Right(userEntity);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseErrorMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userEntity = await remoteDataSource.getCurrentUser();
      if (userEntity != null) {
        return Right(userEntity);
      }
      return const Left(AuthFailure('No active session found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _mapFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
