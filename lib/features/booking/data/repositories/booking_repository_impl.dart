import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';
import 'package:doctor_booking_app/features/booking/domain/repositories/booking_repository.dart';
import 'package:doctor_booking_app/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:doctor_booking_app/features/booking/data/models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BookingEntity>> bookAppointment(
    BookingEntity booking,
  ) async {
    try {
      final bookingModel = BookingModel(
        id: booking.id,
        doctorId: booking.doctorId,
        userId: booking.userId,
        startTime: booking.startTime,
        endTime: booking.endTime,
        durationMinutes: booking.durationMinutes,
        totalAmount: booking.totalAmount,
        commission: booking.commission,
        doctorEarning: booking.doctorEarning,
        status: booking.status,
      );
      final result = await remoteDataSource.bookAppointment(bookingModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getPatientBookings(
    String userId,
  ) async {
    try {
      final bookings = await remoteDataSource.getPatientBookings(userId);
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getDoctorBookings(
    String doctorId,
  ) async {
    try {
      final bookings = await remoteDataSource.getDoctorBookings(doctorId);
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await remoteDataSource.updateBookingStatus(bookingId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getAllBookings() async {
    try {
      final bookings = await remoteDataSource.getAllBookings();
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
