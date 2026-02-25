import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

abstract class DoctorRepository {
  Stream<List<DoctorEntity>> getDoctors({String? specialization});
  Stream<DoctorEntity> getDoctorProfile(String doctorId);
  Future<Either<Failure, void>> updateAvailability(
    String doctorId,
    bool isOnline,
  );
  Future<Either<Failure, void>> updateTimeSlots(
    String doctorId,
    List<String> slots,
  );
  Future<Either<Failure, void>> updateConsultationFee(
    String doctorId,
    double fee,
  );
  // Admin
  Stream<List<DoctorEntity>> getPendingDoctorsStream();
  Stream<List<DoctorEntity>> getAllDoctorsStream();
  Future<Either<Failure, void>> approveDoctor(String doctorId);
  Future<Either<Failure, void>> rejectDoctor(String doctorId);
  Future<Either<Failure, void>> blockDoctor(String doctorId, bool blocked);
  Stream<List<UserEntity>> getAllUsersStream();
  Future<Either<Failure, void>> blockUser(String userId, bool blocked);
}
