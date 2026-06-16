import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String hospitalId;
  final String hospitalName;
  final String departmentId;
  final String departmentName;
  final String doctorName;
  final DateTime appointmentDate;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime? bookedAt;
  final String? symptoms;
  final String? notes;
  final double? consultationFee;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.hospitalId,
    required this.hospitalName,
    required this.departmentId,
    required this.departmentName,
    required this.doctorName,
    required this.appointmentDate,
    required this.status,
    this.bookedAt,
    this.symptoms,
    this.notes,
    this.consultationFee,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      departmentId: data['departmentId'] ?? '',
      departmentName: data['departmentName'] ?? '',
      doctorName: data['doctorName'] ?? 'N/A',
      appointmentDate: data['appointmentDate'] != null
          ? (data['appointmentDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'pending',
      bookedAt: data['bookedAt'] != null
          ? (data['bookedAt'] as Timestamp).toDate()
          : null,
      symptoms: data['symptoms'],
      notes: data['notes'],
      consultationFee: data['consultationFee']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'doctorName': doctorName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'status': status,
      'bookedAt': bookedAt != null
          ? Timestamp.fromDate(bookedAt!)
          : FieldValue.serverTimestamp(),
      if (symptoms != null) 'symptoms': symptoms,
      if (notes != null) 'notes': notes,
      if (consultationFee != null) 'consultationFee': consultationFee,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String getStatusColor() {
    switch (status) {
      case 'pending':
        return 'FFF59E0B'; // Amber
      case 'confirmed':
        return 'FF10B981'; // Green
      case 'cancelled':
        return 'FFEF4444'; // Red
      case 'completed':
        return 'FF0EA5E9'; // Blue
      default:
        return 'FF64748B'; // Gray
    }
  }
}
