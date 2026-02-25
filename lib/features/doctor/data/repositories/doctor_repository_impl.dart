import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/doctor/domain/repositories/doctor_repository.dart';
import 'package:doctor_booking_app/features/doctor/data/datasources/doctor_remote_data_source.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<DoctorEntity>> getDoctors({String? specialization}) {
    return remoteDataSource
        .getDoctors(specialization: specialization)
        .map((list) => list.cast<DoctorEntity>().toList());
  }

  @override
  Stream<DoctorEntity> getDoctorProfile(String doctorId) {
    return remoteDataSource.getDoctorProfile(doctorId).cast<DoctorEntity>();
  }

  @override
  Future<Either<Failure, void>> updateAvailability(
    String doctorId,
    bool isOnline,
  ) async {
    try {
      await remoteDataSource.updateAvailability(doctorId, isOnline);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTimeSlots(
    String doctorId,
    List<String> slots,
  ) async {
    try {
      await remoteDataSource.updateTimeSlots(doctorId, slots);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateConsultationFee(
    String doctorId,
    double fee,
  ) async {
    try {
      await remoteDataSource.updateConsultationFee(doctorId, fee);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<DoctorEntity>> getPendingDoctorsStream() {
    return remoteDataSource.getPendingDoctorsStream().map(
      (list) => list.cast<DoctorEntity>().toList(),
    );
  }

  @override
  Stream<List<DoctorEntity>> getAllDoctorsStream() {
    return remoteDataSource.getAllDoctorsStream().map(
      (list) => list.cast<DoctorEntity>().toList(),
    );
  }

  @override
  Future<Either<Failure, void>> approveDoctor(String doctorId) async {
    try {
      await remoteDataSource.approveDoctor(doctorId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectDoctor(String doctorId) async {
    try {
      await remoteDataSource.rejectDoctor(doctorId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> blockDoctor(
    String doctorId,
    bool blocked,
  ) async {
    try {
      await remoteDataSource.blockDoctor(doctorId, blocked);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<UserEntity>> getAllUsersStream() {
    return remoteDataSource.getAllUsersStream().map(
      (list) => list.cast<UserEntity>().toList(),
    );
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId, bool blocked) async {
    try {
      await remoteDataSource.blockUser(userId, blocked);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
