import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.photoUrl,
    this.dateOfBirth,
    this.bloodGroup,
    this.allergies = const [],
    this.medicalHistory = const [],
    this.insuranceProvider,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? photoUrl;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> medicalHistory;
  final String? insuranceProvider;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPatient => role == AppConstants.rolePatient;
  bool get isHospital => role == AppConstants.roleHospital;
  bool get isAdmin => role == AppConstants.roleAdmin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, id: doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, {required String id}) {
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? AppConstants.rolePatient,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      dateOfBirth: _toDateTime(data['dateOfBirth']),
      bloodGroup: data['bloodGroup'] as String?,
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalHistory: List<String>.from(data['medicalHistory'] ?? []),
      insuranceProvider: data['insuranceProvider'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'role': role,
    'phone': phone,
    'photoUrl': photoUrl,
    'dateOfBirth': dateOfBirth != null
        ? Timestamp.fromDate(dateOfBirth!)
        : null,
    'bloodGroup': bloodGroup,
    'allergies': allergies,
    'medicalHistory': medicalHistory,
    'insuranceProvider': insuranceProvider,
    'fcmToken': fcmToken,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? insuranceProvider,
    String? fcmToken,
  }) => UserModel(
    id: id,
    email: email,
    name: name ?? this.name,
    role: role,
    phone: phone ?? this.phone,
    photoUrl: photoUrl ?? this.photoUrl,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    bloodGroup: bloodGroup ?? this.bloodGroup,
    allergies: allergies ?? this.allergies,
    medicalHistory: medicalHistory ?? this.medicalHistory,
    insuranceProvider: insuranceProvider ?? this.insuranceProvider,
    fcmToken: fcmToken ?? this.fcmToken,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props => [id, email, name, role];
}
