import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class DoctorEvent extends Equatable {
  const DoctorEvent();
  @override
  List<Object?> get props => [];
}

class GetDoctorsEvent extends DoctorEvent {
  final String? specialization;
  const GetDoctorsEvent({this.specialization});
}

class GetDoctorProfileEvent extends DoctorEvent {
  final String doctorId;
  const GetDoctorProfileEvent(this.doctorId);
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

// Admin events
class GetPendingDoctorsEvent extends DoctorEvent {}

class ApproveDoctorEvent extends DoctorEvent {
  final String doctorId;
  const ApproveDoctorEvent(this.doctorId);
}

class RejectDoctorEvent extends DoctorEvent {
  final String doctorId;
  const RejectDoctorEvent(this.doctorId);
}

class GetAllDoctorsEvent extends DoctorEvent {}

class BlockDoctorEvent extends DoctorEvent {
  final String doctorId;
  final bool blocked;
  const BlockDoctorEvent(this.doctorId, this.blocked);
}

class GetAllUsersEvent extends DoctorEvent {}

class BlockUserEvent extends DoctorEvent {
  final String userId;
  final bool blocked;
  const BlockUserEvent(this.userId, this.blocked);
}

class UpdateConsultationFeeEvent extends DoctorEvent {
  final String doctorId;
  final double fee;
  const UpdateConsultationFeeEvent(this.doctorId, this.fee);
}

// Internal stream events
class _DoctorsStreamUpdated extends DoctorEvent {
  final List<DoctorEntity> doctors;
  const _DoctorsStreamUpdated(this.doctors);
}

class _UsersStreamUpdated extends DoctorEvent {
  final List<UserEntity> users;
  const _UsersStreamUpdated(this.users);
}

// ── States ────────────────────────────────────────────────────────────────────
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
  @override
  List<Object?> get props => [doctors];
}

class UsersLoaded extends DoctorState {
  final List<UserEntity> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class DoctorError extends DoctorState {
  final String message;
  const DoctorError(this.message);
  @override
  List<Object?> get props => [message];
}

class DoctorProfileLoaded extends DoctorState {
  final DoctorEntity doctor;
  const DoctorProfileLoaded(this.doctor);
  @override
  List<Object?> get props => [doctor];
}

class DoctorAvailabilityUpdated extends DoctorState {
  final bool isOnline;
  const DoctorAvailabilityUpdated(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository repository;

  StreamSubscription<List<DoctorEntity>>? _pendingDoctorsSubscription;
  StreamSubscription<List<DoctorEntity>>? _allDoctorsSubscription;
  StreamSubscription<List<UserEntity>>? _allUsersSubscription;

  DoctorBloc({required this.repository}) : super(DoctorInitial()) {
    on<GetDoctorsEvent>(_onGetDoctors, transformer: concurrent());
    on<GetDoctorProfileEvent>(_onGetDoctorProfile, transformer: restartable());
    on<UpdateAvailabilityEvent>(_onUpdateAvailability);
    on<UpdateSlotsEvent>(_onUpdateSlots);
    on<UpdateConsultationFeeEvent>(_onUpdateConsultationFee);
    // Admin
    on<GetPendingDoctorsEvent>(_onGetPendingDoctors);
    on<ApproveDoctorEvent>(_onApproveDoctor);
    on<RejectDoctorEvent>(_onRejectDoctor);
    on<GetAllDoctorsEvent>(_onGetAllDoctors);
    on<BlockDoctorEvent>(_onBlockDoctor);
    on<GetAllUsersEvent>(_onGetAllUsers);
    on<BlockUserEvent>(_onBlockUser);
    // Internal stream forwarders
    on<_DoctorsStreamUpdated>((e, emit) => emit(DoctorsLoaded(e.doctors)));
    on<_UsersStreamUpdated>((e, emit) => emit(UsersLoaded(e.users)));
  }

  Future<void> _onGetDoctors(
    GetDoctorsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    await emit.forEach<List<DoctorEntity>>(
      repository.getDoctors(specialization: event.specialization),
      onData: (doctors) => DoctorsLoaded(doctors),
      onError: (error, stackTrace) => DoctorError(error.toString()),
    );
  }

  Future<void> _onGetDoctorProfile(
    GetDoctorProfileEvent event,
    Emitter<DoctorState> emit,
  ) async {
    await emit.forEach<DoctorEntity>(
      repository.getDoctorProfile(event.doctorId),
      onData: (doctor) => DoctorProfileLoaded(doctor),
      onError: (error, stackTrace) => DoctorError(error.toString()),
    );
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailabilityEvent event,
    Emitter<DoctorState> emit,
  ) async {
    try {
      await repository.updateAvailability(event.doctorId, event.isOnline);
    } catch (e) {
      emit(DoctorError(e.toString()));
    }
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

  Future<void> _onUpdateConsultationFee(
    UpdateConsultationFeeEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.updateConsultationFee(
      event.doctorId,
      event.fee,
    );
    result.fold(
      (failure) => emit(DoctorError(failure.message)),
      (_) => add(const GetDoctorsEvent()),
    );
  }

  // ── Admin handlers — persistent StreamSubscriptions ─────────────────────

  Future<void> _onGetPendingDoctors(
    GetPendingDoctorsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    await _pendingDoctorsSubscription?.cancel();
    _pendingDoctorsSubscription = repository.getPendingDoctorsStream().listen(
      (doctors) {
        if (!isClosed) add(_DoctorsStreamUpdated(doctors));
      },
      onError: (e) {
        if (!isClosed) emit(DoctorError(e.toString()));
      },
    );
  }

  Future<void> _onApproveDoctor(
    ApproveDoctorEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.approveDoctor(event.doctorId);
    result.fold((failure) => emit(DoctorError(failure.message)), (_) {});
    // Stream auto-refreshes — no need to re-fetch manually
  }

  Future<void> _onRejectDoctor(
    RejectDoctorEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.rejectDoctor(event.doctorId);
    result.fold((failure) => emit(DoctorError(failure.message)), (_) {});
  }

  Future<void> _onGetAllDoctors(
    GetAllDoctorsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    await _allDoctorsSubscription?.cancel();
    _allDoctorsSubscription = repository.getAllDoctorsStream().listen(
      (doctors) {
        if (!isClosed) add(_DoctorsStreamUpdated(doctors));
      },
      onError: (e) {
        if (!isClosed) emit(DoctorError(e.toString()));
      },
    );
  }

  Future<void> _onBlockDoctor(
    BlockDoctorEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.blockDoctor(event.doctorId, event.blocked);
    result.fold((failure) => emit(DoctorError(failure.message)), (_) {});
  }

  Future<void> _onGetAllUsers(
    GetAllUsersEvent event,
    Emitter<DoctorState> emit,
  ) async {
    await _allUsersSubscription?.cancel();
    _allUsersSubscription = repository.getAllUsersStream().listen(
      (users) {
        if (!isClosed) add(_UsersStreamUpdated(users));
      },
      onError: (e) {
        if (!isClosed) emit(DoctorError(e.toString()));
      },
    );
  }

  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<DoctorState> emit,
  ) async {
    final result = await repository.blockUser(event.userId, event.blocked);
    result.fold((failure) => emit(DoctorError(failure.message)), (_) {});
  }

  @override
  Future<void> close() async {
    await _pendingDoctorsSubscription?.cancel();
    await _allDoctorsSubscription?.cancel();
    await _allUsersSubscription?.cancel();
    return super.close();
  }
}
