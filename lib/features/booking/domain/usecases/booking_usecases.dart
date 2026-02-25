import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/entities/booking_entity.dart';

class BookAppointmentUseCase {
  final BookingRepository repository;
  BookAppointmentUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call(BookingEntity booking) {
    return repository.bookAppointment(booking);
  }
}

class GetPatientBookingsUseCase {
  final BookingRepository repository;
  GetPatientBookingsUseCase(this.repository);

  Stream<List<BookingEntity>> call(String userId) {
    return repository.getPatientBookings(userId);
  }
}
