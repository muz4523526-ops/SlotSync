import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String hospitalId;
  final String name;
  final String doctor;
  final String specialty;
  final double consultationFee;
  final DateTime? createdAt;

  DepartmentModel({
    required this.id,
    required this.hospitalId,
    required this.name,
    required this.doctor,
    required this.specialty,
    required this.consultationFee,
    this.createdAt,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      hospitalId: data['hospitalId'] ?? '',
      name: data['name'] ?? '',
      doctor: data['doctor'] ?? '',
      specialty: data['specialty'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'name': name,
      'doctor': doctor,
      'specialty': specialty,
      'consultationFee': consultationFee,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get formattedFee => '\$${consultationFee.toStringAsFixed(2)}';
}
