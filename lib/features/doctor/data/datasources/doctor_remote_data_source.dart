import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import 'package:doctor_booking_app/features/auth/data/models/user_model.dart';

abstract class DoctorRemoteDataSource {
  Stream<List<DoctorModel>> getDoctors({String? specialization});
  Stream<DoctorModel> getDoctorProfile(String doctorId);
  Future<void> updateAvailability(String doctorId, bool isOnline);
  Future<void> updateTimeSlots(String doctorId, List<String> slots);
  Future<void> updateConsultationFee(String doctorId, double fee);
  // Admin — doctor management
  Stream<List<DoctorModel>> getPendingDoctorsStream();
  Stream<List<DoctorModel>> getAllDoctorsStream();
  Future<void> approveDoctor(String doctorId);
  Future<void> rejectDoctor(String doctorId);
  Future<void> blockDoctor(String doctorId, bool blocked);
  // Admin — user management
  Stream<List<UserModel>> getAllUsersStream();
  Future<void> blockUser(String userId, bool blocked);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final FirebaseFirestore firestore;

  DoctorRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<DoctorModel>> getDoctors({String? specialization}) {
    Query query = firestore
        .collection('doctors')
        .where('isApproved', isEqualTo: true)
        .where('isBlocked', isEqualTo: false);
    if (specialization != null) {
      query = query.where('specialization', isEqualTo: specialization);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => DoctorModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  @override
  Stream<DoctorModel> getDoctorProfile(String doctorId) {
    return firestore.collection('doctors').doc(doctorId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        return DoctorModel.fromJson(data);
      }
      throw Exception('Doctor profile not found');
    });
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

  // ── Admin: pending approvals (real-time stream) ────────────────────────────
  @override
  Stream<List<DoctorModel>> getPendingDoctorsStream() {
    return firestore
        .collection('doctors')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final results = <DoctorModel>[];
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Skip rejected doctors; treat missing field as not-rejected
            if (data['isRejected'] == true) continue;
            results.add(DoctorModel.fromJson(data));
          }
          return results;
        });
  }

  // ── Admin: all doctors (real-time stream) ─────────────────────────────────
  @override
  Stream<List<DoctorModel>> getAllDoctorsStream() {
    return firestore
        .collection('doctors')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    DoctorModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  @override
  Future<void> approveDoctor(String doctorId) async {
    await firestore.collection('doctors').doc(doctorId).update({
      'isApproved': true,
    });
  }

  @override
  Future<void> rejectDoctor(String doctorId) async {
    // Keep isApproved false and add a rejectedAt timestamp so the doctor knows
    await firestore.collection('doctors').doc(doctorId).update({
      'isApproved': false,
      'isRejected': true,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> blockDoctor(String doctorId, bool blocked) async {
    await firestore.collection('doctors').doc(doctorId).update({
      'isBlocked': blocked,
    });
  }

  // ── Admin: all users (patients) ────────────────────────────────────────────
  @override
  Stream<List<UserModel>> getAllUsersStream() {
    return firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  @override
  Future<void> blockUser(String userId, bool blocked) async {
    await firestore.collection('users').doc(userId).update({
      'isBlocked': blocked,
    });
  }
}
