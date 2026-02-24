import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';

// Events
abstract class DoctorEvent extends Equatable {
  const DoctorEvent();
  @override
  List<Object?> get props => [];
}

class GetDoctorsEvent extends DoctorEvent {
  final String? specialization;
  const GetDoctorsEvent({this.specialization});
}

class UpdateAvailabilityEvent extends DoctorEvent {
  final String doctorId;
  final bool isOnline;
  const UpdateAvailabilityEvent(this.doctorId, this.isOnline);
}

class UpdateSlotsEvent extends DoctorEvent {
  final String doctorId;
  final List<String> slots;
  const UpdateSlotsEvent(this.doctorId, this.slots);
}

class GetPendingDoctorsEvent extends DoctorEvent {}

class ApproveDoctorEvent extends DoctorEvent {
  final String doctorId;
  const ApproveDoctorEvent(this.doctorId);
}

// States
abstract class DoctorState extends Equatable {
  const DoctorState();
  @override
  List<Object?> get props => [];
}

class DoctorInitial extends DoctorState {}

class DoctorLoading extends DoctorState {}

class DoctorsLoaded extends DoctorState {
  final List<DoctorEntity> doctors;
  const DoctorsLoaded(this.doctors);
}

class DoctorError extends DoctorState {
  final String message;
  const DoctorError(this.message);
}

// BLoC
class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository repository;

  DoctorBloc({required this.repository}) : super(DoctorInitial()) {
    on<GetDoctorsEvent>(_onGetDoctors);
    on<UpdateAvailabilityEvent>(_onUpdateAvailability);
    on<UpdateSlotsEvent>(_onUpdateSlots);
    on<GetPendingDoctorsEvent>(_onGetPendingDoctors);
    on<ApproveDoctorEvent>(_onApproveDoctor);
  }

  Future<void> _onGetDoctors(
    GetDoctorsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    try {
      emit(DoctorLoading());
      final result = await repository.getDoctors(
        specialization: event.specialization,
      );
      result.fold(
        (failure) => emit(DoctorError(failure.message)),
        (doctors) => emit(DoctorsLoaded(doctors)),
      );
    } catch (e) {
      emit(DoctorError('Failed to load doctors: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailabilityEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.updateAvailability(
      event.doctorId,
      event.isOnline,
    );
    result.fold(
      (failure) => emit(DoctorError(failure.message)),
      (_) => add(const GetDoctorsEvent()), // Refresh or emit success state
    );
  }

  Future<void> _onUpdateSlots(
    UpdateSlotsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.updateTimeSlots(
      event.doctorId,
      event.slots,
    );
    result.fold(
      (failure) => emit(DoctorError(failure.message)),
      (_) => add(const GetDoctorsEvent()),
    );
  }

  Future<void> _onGetPendingDoctors(
    GetPendingDoctorsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    try {
      emit(DoctorLoading());
      final result = await repository.getPendingDoctors();
      result.fold(
        (failure) => emit(DoctorError(failure.message)),
        (doctors) => emit(DoctorsLoaded(doctors)),
      );
    } catch (e) {
      emit(DoctorError('Failed to load pending doctors: ${e.toString()}'));
    }
  }

  Future<void> _onApproveDoctor(
    ApproveDoctorEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.approveDoctor(event.doctorId);
    result.fold(
      (failure) => emit(DoctorError(failure.message)),
      (_) => add(GetPendingDoctorsEvent()),
    );
  }
}
