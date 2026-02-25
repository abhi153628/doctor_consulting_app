import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/booking/domain/entities/booking_entity.dart';

abstract class BookingRepository {
  Future<Either<Failure, BookingEntity>> bookAppointment(BookingEntity booking);
  Stream<List<BookingEntity>> getPatientBookings(String userId);
  Stream<List<BookingEntity>> getDoctorBookings(String doctorId);
  Future<Either<Failure, void>> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  );
  Future<Either<Failure, List<BookingEntity>>>
  getAllBookings(); // Admin (one-shot)
  Stream<List<BookingEntity>> getAllBookingsStream(); // Admin (real-time)
}
