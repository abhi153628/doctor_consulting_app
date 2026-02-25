import 'package:equatable/equatable.dart';

enum UserRole { patient, doctor, admin }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;
  final String? phoneNumber;
  final bool isBlocked;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    this.phoneNumber,
    this.isBlocked = false,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    profileImageUrl,
    phoneNumber,
    isBlocked,
  ];
}
