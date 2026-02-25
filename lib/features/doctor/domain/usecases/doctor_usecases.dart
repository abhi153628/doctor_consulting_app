import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../../domain/entities/doctor_entity.dart';

class GetDoctorsUseCase {
  final DoctorRepository repository;
  GetDoctorsUseCase(this.repository);

  Stream<List<DoctorEntity>> call({String? specialization}) {
    return repository.getDoctors(specialization: specialization);
  }
}

class UpdateAvailabilityUseCase {
  final DoctorRepository repository;
  UpdateAvailabilityUseCase(this.repository);

  Future<Either<Failure, void>> call(String doctorId, bool isOnline) {
    return repository.updateAvailability(doctorId, isOnline);
  }
}
