import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';

abstract class BookingRepository {
  Future<Either<Failure, BookingEntity>> bookAppointment(BookingEntity booking);
  Future<Either<Failure, List<BookingEntity>>> getPatientBookings(
    String userId,
  );
  Future<Either<Failure, List<BookingEntity>>> getDoctorBookings(
    String doctorId,
  );
  Future<Either<Failure, void>> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  );
  Future<Either<Failure, List<BookingEntity>>> getAllBookings(); // Admin
}
