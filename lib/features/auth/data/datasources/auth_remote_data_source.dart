import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/data/models/user_model.dart';
import 'package:doctor_booking_app/features/doctor/data/models/doctor_model.dart';

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

    if (role == UserRole.doctor) {
      final doctorModel = DoctorModel(
        id: credential.user?.uid ?? '',
        email: email,
        name: name,
        role: role,
        specialization: specialization ?? '',
        isApproved: true,
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
        id: credential.user?.uid ?? '',
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

    final doctorDoc = await firestore.collection('doctors').doc(uid).get();
    if (doctorDoc.exists && doctorDoc.data() != null) {
      return DoctorModel.fromJson(doctorDoc.data()!);
    }

    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      return UserModel.fromJson(userDoc.data()!);
    }

    throw Exception('User data not found in registration records');
  }

  @override
  Future<void> logout() => firebaseAuth.signOut();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    final doctorDoc = await firestore.collection('doctors').doc(user.uid).get();
    if (doctorDoc.exists && doctorDoc.data() != null) {
      return DoctorModel.fromJson(doctorDoc.data()!);
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      return UserModel.fromJson(userDoc.data()!);
    }

    return null;
  }
}
