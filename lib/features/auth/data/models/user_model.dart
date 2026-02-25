import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final bool? isApproved;
  final bool isBlocked;

  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.profileImageUrl,
    super.phoneNumber,
    this.isApproved,
    this.isBlocked = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      profileImageUrl: json['profileImageUrl'],
      phoneNumber: json['phoneNumber'],
      isApproved: json['isApproved'],
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'isBlocked': isBlocked,
    };
  }
}
