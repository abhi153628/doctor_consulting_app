import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';

// Events
abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class BookAppointmentEvent extends BookingEvent {
  final BookingEntity booking;
  const BookAppointmentEvent(this.booking);
}

class GetPatientBookingsEvent extends BookingEvent {
  final String userId;
  const GetPatientBookingsEvent(this.userId);
}

class GetDoctorBookingsEvent extends BookingEvent {
  final String doctorId;
  const GetDoctorBookingsEvent(this.doctorId);
}

class UpdateBookingStatusEvent extends BookingEvent {
  final String bookingId;
  final BookingStatus status;
  const UpdateBookingStatusEvent(this.bookingId, this.status);
}

// States
abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<BookingEntity> bookings;
  const BookingsLoaded(this.bookings);
}

class BookingSuccess extends BookingState {
  final BookingEntity booking;
  const BookingSuccess(this.booking);
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
}

// BLoC
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository repository;

  BookingBloc({required this.repository}) : super(BookingInitial()) {
    on<BookAppointmentEvent>(_onBookAppointment);
    on<GetPatientBookingsEvent>(_onGetPatientBookings);
    on<GetDoctorBookingsEvent>(_onGetDoctorBookings);
    on<UpdateBookingStatusEvent>(_onUpdateBookingStatus);
  }

  Future<void> _onBookAppointment(
    BookAppointmentEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.bookAppointment(event.booking);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingSuccess(booking)),
    );
  }

  Future<void> _onGetPatientBookings(
    GetPatientBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.getPatientBookings(event.userId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (bookings) => emit(BookingsLoaded(bookings)),
    );
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatusEvent event,
    Emitter<BookingState> emit,
  ) async {
    await repository.updateBookingStatus(event.bookingId, event.status);
    // Reload logic usually added in UI or here by re-dispatching event
  }

  Future<void> _onGetDoctorBookings(
    GetDoctorBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await repository.getDoctorBookings(event.doctorId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (bookings) => emit(BookingsLoaded(bookings)),
    );
  }
}
