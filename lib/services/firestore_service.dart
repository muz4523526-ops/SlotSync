import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Get all hospitals
  Stream<QuerySnapshot> getHospitals() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'hospital')
        .snapshots();
  }

  // Add department (for hospitals)
  Future<void> addDepartment({
    required String hospitalId,
    required String name,
    required String doctor,
    required String specialty,
    required double consultationFee,
  }) async {
    await _firestore.collection('departments').add({
      'hospitalId': hospitalId,
      'name': name,
      'doctor': doctor,
      'specialty': specialty,
      'consultationFee': consultationFee,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get departments for a hospital
  Stream<QuerySnapshot> getDepartments(String hospitalId) {
    return _firestore
        .collection('departments')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots();
  }

  // Book appointment
  Future<void> bookAppointment({
    required String patientId,
    required String patientName,
    required String hospitalId,
    required String hospitalName,
    required String departmentId,
    required String departmentName,
    required String doctorName,
    required DateTime appointmentDate,
    required String status,
  }) async {
    await _firestore.collection('appointments').add({
      'patientId': patientId,
      'patientName': patientName,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'doctorName': doctorName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'status': status, // 'pending', 'confirmed', 'cancelled', 'completed'
      'bookedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get patient appointments
  Stream<QuerySnapshot> getPatientAppointments(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: true)
        .snapshots();
  }

  // Get hospital appointments
  Stream<QuerySnapshot> getHospitalAppointments(String hospitalId) {
    _logger.d('Fetching hospital appointments for: $hospitalId');
    return _firestore
        .collection('appointments')
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('appointmentDate', descending: true)
        .snapshots();
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
    });
  }
}
