import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String role; // 'patient' or 'hospital'
  final DateTime? createdAt;

  // Hospital-specific fields
  final String? hospitalName;
  final double? googleRating;
  final String? googleMapsLink;
  final String? address;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
    this.hospitalName,
    this.googleRating,
    this.googleMapsLink,
    this.address,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'patient',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      hospitalName: data['hospitalName'],
      googleRating: data['googleRating']?.toDouble(),
      googleMapsLink: data['googleMapsLink'],
      address: data['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      if (hospitalName != null) 'hospitalName': hospitalName,
      if (googleRating != null) 'googleRating': googleRating,
      if (googleMapsLink != null) 'googleMapsLink': googleMapsLink,
      if (address != null) 'address': address,
    };
  }

  bool get isHospital => role == 'hospital';
  bool get isPatient => role == 'patient';
}
