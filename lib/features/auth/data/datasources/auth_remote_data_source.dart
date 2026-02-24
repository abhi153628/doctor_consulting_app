import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? specialization,
    String? phoneNumber,
  });
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> signUp({
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

    final userModel = UserModel(
      id: credential.user?.uid ?? '',
      email: email,
      name: name,
      role: role,
      isApproved: role == UserRole.doctor ? true : null,
      phoneNumber: phoneNumber,
    );

    if (role == UserRole.doctor) {
      await firestore.collection('doctors').doc(userModel.id).set({
        ...userModel.toJson(),
        'specialization': specialization,
        'isApproved': true,
        'isOnline': false,
        'availableTimeSlots': [],
        'rating': 0.0,
        'totalConsultations': 0,
        'phoneNumber': phoneNumber,
      });
    } else {
      await firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson());
    }

    return userModel;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Check if doctor or user
    final uid = credential.user?.uid;
    if (uid == null) throw Exception('User authentication failed');

    final doctorDoc = await firestore.collection('doctors').doc(uid).get();
    final doctorData = doctorDoc.data();
    if (doctorDoc.exists && doctorData != null) {
      return UserModel.fromJson(doctorData);
    }

    final userDoc = await firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();
    if (userDoc.exists && userData != null) {
      return UserModel.fromJson(userData);
    }

    throw Exception('User data not found in registration records');
  }

  @override
  Future<void> logout() => firebaseAuth.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    final doctorDoc = await firestore.collection('doctors').doc(user.uid).get();
    final doctorData = doctorDoc.data();
    if (doctorDoc.exists && doctorData != null) {
      return UserModel.fromJson(doctorData);
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userDoc.exists && userData != null) {
      return UserModel.fromJson(userData);
    }

    return null;
  }
}
