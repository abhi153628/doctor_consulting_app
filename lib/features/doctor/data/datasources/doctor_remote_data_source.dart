import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

abstract class DoctorRemoteDataSource {
  Future<List<DoctorModel>> getDoctors({String? specialization});
  Future<DoctorModel> getDoctorProfile(String doctorId);
  Future<void> updateAvailability(String doctorId, bool isOnline);
  Future<void> updateTimeSlots(String doctorId, List<String> slots);
  Future<void> updateConsultationFee(String doctorId, double fee);
  Future<List<DoctorModel>> getPendingDoctors();
  Future<void> approveDoctor(String doctorId);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final FirebaseFirestore firestore;

  DoctorRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<DoctorModel>> getDoctors({String? specialization}) async {
    Query query = firestore
        .collection('doctors')
        .where('isApproved', isEqualTo: true);
    if (specialization != null) {
      query = query.where('specialization', isEqualTo: specialization);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => DoctorModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DoctorModel> getDoctorProfile(String doctorId) async {
    final doc = await firestore.collection('doctors').doc(doctorId).get();
    final data = doc.data();
    if (doc.exists && data != null) {
      return DoctorModel.fromJson(data);
    }
    throw Exception('Doctor profile not found');
  }

  @override
  Future<void> updateAvailability(String doctorId, bool isOnline) async {
    await firestore.collection('doctors').doc(doctorId).update({
      'isOnline': isOnline,
    });
  }

  @override
  Future<void> updateTimeSlots(String doctorId, List<String> slots) async {
    await firestore.collection('doctors').doc(doctorId).update({
      'availableTimeSlots': slots,
    });
  }

  @override
  Future<void> updateConsultationFee(String doctorId, double fee) async {
    await firestore.collection('doctors').doc(doctorId).update({
      'consultationFee': fee,
    });
  }

  @override
  Future<List<DoctorModel>> getPendingDoctors() async {
    final snapshot = await firestore
        .collection('doctors')
        .where('isApproved', isEqualTo: false)
        .get();
    return snapshot.docs
        .map((doc) => DoctorModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> approveDoctor(String doctorId) async {
    await firestore.collection('doctors').doc(doctorId).update({
      'isApproved': true,
    });
  }
}
