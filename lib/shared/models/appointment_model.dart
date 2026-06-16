import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class AppointmentModel extends Equatable {
  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.hospitalId,
    required this.appointmentDate,
    this.patientName,
    this.hospitalName,
    this.departmentId,
    this.departmentName,
    this.serviceId,
    this.serviceName,
    this.doctorName,
    this.slotId,
    this.status = AppConstants.statusPending,
    this.notes,
    this.consultationFee = 0,
    this.qrCode,
    this.documentUrls = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String hospitalId;
  final DateTime appointmentDate;
  final String? patientName;
  final String? hospitalName;
  final String? departmentId;
  final String? departmentName;
  final String? serviceId;
  final String? serviceName;
  final String? doctorName;
  final String? slotId;
  final String status;
  final String? notes;
  final double consultationFee;
  final String? qrCode;
  final List<String> documentUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) &&
      status != AppConstants.statusCancelled;

  bool get isPast => appointmentDate.isBefore(DateTime.now());

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppointmentModel.fromMap(data, id: doc.id);
  }

  factory AppointmentModel.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return AppointmentModel(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      hospitalId: data['hospitalId'] as String? ?? '',
      appointmentDate: _toDateTime(data['appointmentDate']) ?? DateTime.now(),
      patientName: data['patientName'] as String?,
      hospitalName: data['hospitalName'] as String?,
      departmentId: data['departmentId'] as String?,
      departmentName: data['departmentName'] as String?,
      serviceId: data['serviceId'] as String?,
      serviceName: data['serviceName'] as String?,
      doctorName: data['doctorName'] as String?,
      slotId: data['slotId'] as String?,
      status: data['status'] as String? ?? AppConstants.statusPending,
      notes: data['notes'] as String?,
      consultationFee: (data['consultationFee'] as num?)?.toDouble() ?? 0,
      qrCode: data['qrCode'] as String?,
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'patientId': patientId,
    'hospitalId': hospitalId,
    'appointmentDate': Timestamp.fromDate(appointmentDate),
    'patientName': patientName,
    'hospitalName': hospitalName,
    'departmentId': departmentId,
    'departmentName': departmentName,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'doctorName': doctorName,
    'slotId': slotId,
    'status': status,
    'notes': notes,
    'consultationFee': consultationFee,
    'qrCode': qrCode,
    'documentUrls': documentUrls,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    hospitalId,
    appointmentDate,
    status,
  ];
}

class SlotModel extends Equatable {
  const SlotModel({
    required this.id,
    required this.hospitalId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.serviceId,
    this.departmentId,
    this.capacity = 1,
    this.bookedCount = 0,
    this.isBlocked = false,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  final String id;
  final String hospitalId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? serviceId;
  final String? departmentId;
  final int capacity;
  final int bookedCount;
  final bool isBlocked;
  final bool isRecurring;
  final String? recurrenceRule;

  bool get isAvailable => !isBlocked && bookedCount < capacity;

  int get remaining => capacity - bookedCount;

  factory SlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SlotModel.fromMap(data, id: doc.id);
  }

  factory SlotModel.fromMap(Map<String, dynamic> data, {required String id}) {
    return SlotModel(
      id: id,
      hospitalId: data['hospitalId'] as String? ?? '',
      date: _toDateTime(data['date']) ?? DateTime.now(),
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      serviceId: data['serviceId'] as String?,
      departmentId: data['departmentId'] as String?,
      capacity: data['capacity'] as int? ?? 1,
      bookedCount: data['bookedCount'] as int? ?? 0,
      isBlocked: data['isBlocked'] as bool? ?? false,
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrenceRule: data['recurrenceRule'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'hospitalId': hospitalId,
    'date': Timestamp.fromDate(date),
    'startTime': startTime,
    'endTime': endTime,
    'serviceId': serviceId,
    'departmentId': departmentId,
    'capacity': capacity,
    'bookedCount': bookedCount,
    'isBlocked': isBlocked,
    'isRecurring': isRecurring,
    'recurrenceRule': recurrenceRule,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, hospitalId, date, startTime, isBlocked];
}
