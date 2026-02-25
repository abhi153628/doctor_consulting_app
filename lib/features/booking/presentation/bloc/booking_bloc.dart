import 'dart:async';
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

// Admin: listen to all bookings across all doctors
class GetAllBookingsEvent extends BookingEvent {}

// Internal event to push stream data into the BLoC from outside the event queue
class _BookingsStreamUpdated extends BookingEvent {
  final List<BookingEntity> bookings;
  const _BookingsStreamUpdated(this.bookings);
}

class _BookingsStreamErrored extends BookingEvent {
  final String message;
  const _BookingsStreamErrored(this.message);
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

  @override
  List<Object?> get props => [bookings];
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

  // Independent, persistent stream subscriptions
  StreamSubscription<List<BookingEntity>>? _doctorBookingsSubscription;
  StreamSubscription<List<BookingEntity>>? _patientBookingsSubscription;
  StreamSubscription<List<BookingEntity>>? _allBookingsSubscription;

  BookingBloc({required this.repository}) : super(BookingInitial()) {
    on<BookAppointmentEvent>(_onBookAppointment);
    on<GetPatientBookingsEvent>(_onGetPatientBookings);
    on<GetDoctorBookingsEvent>(_onGetDoctorBookings);
    on<GetAllBookingsEvent>(_onGetAllBookings);
    on<UpdateBookingStatusEvent>(_onUpdateBookingStatus);
    // Internal events to safely push stream data into BLoC state
    on<_BookingsStreamUpdated>(
      (event, emit) => emit(BookingsLoaded(event.bookings)),
    );
    on<_BookingsStreamErrored>(
      (event, emit) => emit(BookingError(event.message)),
    );
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

  /// Subscribe to doctor bookings. The subscription is persistent and
  /// independent of other events — it will NOT be cancelled by Accept/Reject.
  Future<void> _onGetDoctorBookings(
    GetDoctorBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    // Cancel any existing doctor subscription before starting a new one
    await _doctorBookingsSubscription?.cancel();
    _doctorBookingsSubscription = null;

    _doctorBookingsSubscription = repository
        .getDoctorBookings(event.doctorId)
        .listen(
          (bookings) {
            if (!isClosed) {
              add(_BookingsStreamUpdated(bookings));
            }
          },
          onError: (error) {
            if (!isClosed) {
              add(_BookingsStreamErrored(error.toString()));
            }
          },
        );
  }

  /// Subscribe to patient bookings. Same persistent pattern.
  Future<void> _onGetPatientBookings(
    GetPatientBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    // Cancel any existing patient subscription before starting a new one
    await _patientBookingsSubscription?.cancel();
    _patientBookingsSubscription = null;

    _patientBookingsSubscription = repository
        .getPatientBookings(event.userId)
        .listen(
          (bookings) {
            if (!isClosed) {
              add(_BookingsStreamUpdated(bookings));
            }
          },
          onError: (error) {
            if (!isClosed) {
              add(_BookingsStreamErrored(error.toString()));
            }
          },
        );
  }

  /// Update Firestore. The Firestore stream subscription above will
  /// automatically pick up the change and push a new BookingsLoaded state.
  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatusEvent event,
    Emitter<BookingState> emit,
  ) async {
    await repository.updateBookingStatus(event.bookingId, event.status);
  }

  /// Subscribe to ALL bookings — for admin monitoring.
  Future<void> _onGetAllBookings(
    GetAllBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    await _allBookingsSubscription?.cancel();
    _allBookingsSubscription = null;
    _allBookingsSubscription = repository.getAllBookingsStream().listen(
      (bookings) {
        if (!isClosed) add(_BookingsStreamUpdated(bookings));
      },
      onError: (error) {
        if (!isClosed) add(_BookingsStreamErrored(error.toString()));
      },
    );
  }

  @override
  Future<void> close() async {
    await _doctorBookingsSubscription?.cancel();
    await _patientBookingsSubscription?.cancel();
    await _allBookingsSubscription?.cancel();
    return super.close();
  }
}
