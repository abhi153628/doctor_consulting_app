import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/doctor/domain/repositories/doctor_repository.dart';
import 'package:doctor_booking_app/features/doctor/data/datasources/doctor_remote_data_source.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DoctorEntity>>> getDoctors({
    String? specialization,
  }) async {
    try {
      final doctors = await remoteDataSource.getDoctors(
        specialization: specialization,
      );
      return Right(doctors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DoctorEntity>> getDoctorProfile(
    String doctorId,
  ) async {
    try {
      final doctor = await remoteDataSource.getDoctorProfile(doctorId);
      return Right(doctor);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
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
  Future<Either<Failure, List<DoctorEntity>>> getPendingDoctors() async {
    try {
      final doctors = await remoteDataSource.getPendingDoctors();
      return Right(doctors);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
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
}
