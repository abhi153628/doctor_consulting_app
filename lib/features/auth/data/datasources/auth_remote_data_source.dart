import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/data/models/user_model.dart';
import 'package:doctor_booking_app/features/doctor/data/models/doctor_model.dart';
import 'package:doctor_booking_app/core/services/notification_service.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? specialization,
    String? phoneNumber,
  });
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();

  /// Real-time stream of isBlocked for the currently logged-in user.
  Stream<bool> watchUserBlockedStatus();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? specialization,
    String? phoneNumber,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid ?? '';
    if (uid.isNotEmpty) {
      await NotificationService.login(uid);
    }

    if (role == UserRole.doctor) {
      final doctorModel = DoctorModel(
        id: uid,
        email: email,
        name: name,
        role: role,
        specialization: specialization ?? '',
        isApproved: false,
        isOnline: false,
        availableTimeSlots: const [],
        rating: 0.0,
        totalConsultations: 0,
        phoneNumber: phoneNumber,
        consultationFee: 500.0,
      );

      await firestore
          .collection('doctors')
          .doc(doctorModel.id)
          .set(doctorModel.toJson());
      return doctorModel;
    } else {
      final userModel = UserModel(
        id: uid,
        email: email,
        name: name,
        role: role,
        isApproved: null,
        phoneNumber: phoneNumber,
      );

      await firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson());
      return userModel;
    }
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) throw Exception('User authentication failed');

    await NotificationService.login(uid);

    final doctorDoc = await firestore.collection('doctors').doc(uid).get();
    if (doctorDoc.exists && doctorDoc.data() != null) {
      final doctor = DoctorModel.fromJson(doctorDoc.data()!);
      if (doctor.isBlocked) {
        await firebaseAuth.signOut();
        throw Exception(
          'BLOCKED:Your account has been blocked by the admin. Please contact support.',
        );
      }
      return doctor;
    }

    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final user = UserModel.fromJson(userDoc.data()!);
      if (user.isBlocked) {
        await firebaseAuth.signOut();
        throw Exception(
          'BLOCKED:Your account has been blocked by the admin. Please contact support.',
        );
      }
      return user;
    }

    throw Exception('User data not found in registration records');
  }

  @override
  Future<void> logout() async {
    await NotificationService.logout();
    await firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    // CRITICAL: Re-link OneSignal UID on every app launch/resume
    NotificationService.login(user.uid);

    final doctorDoc = await firestore.collection('doctors').doc(user.uid).get();
    if (doctorDoc.exists && doctorDoc.data() != null) {
      final doctor = DoctorModel.fromJson(doctorDoc.data()!);
      if (doctor.isBlocked) {
        await firebaseAuth.signOut();
        return null;
      }
      return doctor;
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final u = UserModel.fromJson(userDoc.data()!);
      if (u.isBlocked) {
        await firebaseAuth.signOut();
        return null;
      }
      return u;
    }

    return null;
  }

  /// Streams isBlocked field — emits true the moment admin blocks this user.
  @override
  Stream<bool> watchUserBlockedStatus() {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Check doctors collection first; if not found, check users
    return firestore.collection('doctors').doc(uid).snapshots().asyncMap((
      doctorSnap,
    ) async {
      if (doctorSnap.exists && doctorSnap.data() != null) {
        return doctorSnap.data()!['isBlocked'] == true;
      }
      final userSnap = await firestore.collection('users').doc(uid).get();
      if (userSnap.exists && userSnap.data() != null) {
        return userSnap.data()!['isBlocked'] == true;
      }
      return false;
    });
  }
}
