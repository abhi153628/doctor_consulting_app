import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';

abstract class DoctorRepository {
  Future<Either<Failure, List<DoctorEntity>>> getDoctors({
    String? specialization,
  });
  Future<Either<Failure, DoctorEntity>> getDoctorProfile(String doctorId);
  Future<Either<Failure, void>> updateAvailability(
    String doctorId,
    bool isOnline,
  );
  Future<Either<Failure, void>> updateTimeSlots(
    String doctorId,
    List<String> slots,
  );
  Future<Either<Failure, List<DoctorEntity>>> getPendingDoctors();
  Future<Either<Failure, void>> approveDoctor(String doctorId);
}
