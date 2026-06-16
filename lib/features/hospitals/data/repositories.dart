import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/hospital_model.dart';
import '../../../shared/models/department_model.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/support_models.dart';

class HospitalRepository {
  HospitalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<HospitalModel>> watchHospitals() {
    return _firestore
        .collection(AppConstants.hospitalsCollection)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((s) => s.docs.map(HospitalModel.fromFirestore).toList());
  }

  Future<List<HospitalModel>> searchHospitals({
    String? query,
    String? specialty,
    double? minRating,
    String? insurance,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection(
      AppConstants.hospitalsCollection,
    );

    if (minRating != null) {
      q = q.where('rating', isGreaterThanOrEqualTo: minRating);
    }

    final snapshot = await q.get();
    var hospitals = snapshot.docs.map(HospitalModel.fromFirestore).toList();

    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      hospitals = hospitals.where((h) {
        return h.name.toLowerCase().contains(lower) ||
            (h.city?.toLowerCase().contains(lower) ?? false) ||
            h.specialties.any((s) => s.toLowerCase().contains(lower));
      }).toList();
    }

    if (specialty != null && specialty.isNotEmpty) {
      hospitals = hospitals
          .where(
            (h) => h.specialties.any(
              (s) => s.toLowerCase() == specialty.toLowerCase(),
            ),
          )
          .toList();
    }

    if (insurance != null && insurance.isNotEmpty) {
      hospitals = hospitals
          .where((h) => h.insuranceAccepted.contains(insurance))
          .toList();
    }

    return hospitals;
  }

  Future<HospitalModel?> getHospital(String id) async {
    final doc = await _firestore
        .collection(AppConstants.hospitalsCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return HospitalModel.fromFirestore(doc);
  }

  Future<DepartmentModel?> getDepartment(String id) async {
    final doc = await _firestore
        .collection(AppConstants.departmentsCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return DepartmentModel.fromFirestore(doc);
  }

  Future<ServiceModel?> getService(String id) async {
    final doc = await _firestore
        .collection(AppConstants.servicesCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return ServiceModel.fromFirestore(doc);
  }

  Stream<List<DepartmentModel>> watchDepartments(String hospitalId) {
    return _firestore
        .collection(AppConstants.departmentsCollection)
        .where('hospitalId', isEqualTo: hospitalId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(DepartmentModel.fromFirestore).toList());
  }

  Stream<List<ServiceModel>> watchServices(String hospitalId) {
    return _firestore
        .collection(AppConstants.servicesCollection)
        .where('hospitalId', isEqualTo: hospitalId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(ServiceModel.fromFirestore).toList());
  }

  Future<void> addDepartment(DepartmentModel department) async {
    await _firestore
        .collection(AppConstants.departmentsCollection)
        .add(department.toMap());
  }

  Future<void> updateDepartment(DepartmentModel department) async {
    await _firestore
        .collection(AppConstants.departmentsCollection)
        .doc(department.id)
        .set(department.toMap(), SetOptions(merge: true));
  }

  Future<void> updateService(ServiceModel service) async {
    await _firestore
        .collection(AppConstants.servicesCollection)
        .doc(service.id)
        .set(service.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteService(String serviceId) async {
    await _firestore
        .collection(AppConstants.servicesCollection)
        .doc(serviceId)
        .update({'isActive': false});
  }

  Future<void> addService(ServiceModel service) async {
    await _firestore
        .collection(AppConstants.servicesCollection)
        .add(service.toMap());
  }

  Stream<List<ReviewModel>> watchReviews(String hospitalId) {
    return _firestore
        .collection(AppConstants.reviewsCollection)
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(ReviewModel.fromFirestore).toList());
  }

  Future<void> updateHospitalProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(AppConstants.hospitalsCollection)
        .doc(id)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }
}

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppointmentModel>> watchPatientAppointments(String patientId) {
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Stream<List<AppointmentModel>> watchHospitalAppointments(String hospitalId) {
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Future<List<SlotModel>> getAvailableSlots({
    required String hospitalId,
    required DateTime date,
    String? departmentId,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final q = _firestore
        .collection(AppConstants.slotsCollection)
        .where('hospitalId', isEqualTo: hospitalId);

    final snapshot = await q.get();
    return snapshot.docs
        .map(SlotModel.fromFirestore)
        .where((s) =>
            s.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            s.date.isBefore(endOfDay) &&
            s.isAvailable &&
            (departmentId == null || s.departmentId == departmentId))
        .toList();
  }

  Future<String> bookAppointment(AppointmentModel appointment) async {
    return _firestore.runTransaction((transaction) async {
      if (appointment.slotId != null) {
        final slotRef = _firestore
            .collection(AppConstants.slotsCollection)
            .doc(appointment.slotId);
        final slotDoc = await transaction.get(slotRef);
        if (!slotDoc.exists) throw const FirestoreException('Slot not found');

        final slot = SlotModel.fromFirestore(slotDoc);
        if (!slot.isAvailable) {
          throw const FirestoreException('Slot is no longer available');
        }

        transaction.update(slotRef, {
          'bookedCount': slot.bookedCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final appointmentRef = _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc();
      transaction.set(appointmentRef, appointment.toMap());
      return appointmentRef.id;
    });
  }

  Future<void> updateStatus(String appointmentId, String status) async {
    await _firestore
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.runTransaction((transaction) async {
      final appointmentRef = _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId);
      final appointmentDoc = await transaction.get(appointmentRef);
      if (!appointmentDoc.exists) {
        throw const FirestoreException('Appointment not found');
      }

      final data = appointmentDoc.data()!;
      final slotId = data['slotId'] as String?;

      if (slotId != null) {
        final slotRef = _firestore
            .collection(AppConstants.slotsCollection)
            .doc(slotId);
        final slotDoc = await transaction.get(slotRef);
        if (slotDoc.exists) {
          final bookedCount =
              (slotDoc.data()!['bookedCount'] as num?)?.toInt() ?? 0;
          transaction.update(slotRef, {
            'bookedCount': (bookedCount - 1).clamp(0, 999999),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.update(appointmentRef, {
        'status': AppConstants.statusCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addToWaitlist(WaitlistModel waitlist) async {
    await _firestore
        .collection(AppConstants.waitlistsCollection)
        .add(waitlist.toMap());
  }

  Future<void> createSlot(SlotModel slot) async {
    await _firestore.collection(AppConstants.slotsCollection).add(slot.toMap());
  }

  Stream<List<SlotModel>> watchHospitalSlots(String hospitalId) {
    return _firestore
        .collection(AppConstants.slotsCollection)
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((s) => s.docs
            .map(SlotModel.fromFirestore)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)));
  }
}

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromFirestore).toList());
  }

  Stream<MessageModel?> watchLatestMessage(String conversationId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (s) =>
              s.docs.isEmpty ? null : MessageModel.fromFirestore(s.docs.first),
        );
  }

  Future<void> sendMessage(MessageModel message) async {
    await _firestore
        .collection(AppConstants.messagesCollection)
        .add(message.toMap());
  }

  Future<void> markAsRead(String messageId) async {
    await _firestore
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({'isRead': true});
  }

  Future<void> markConversationAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final hospitalRepositoryProvider = Provider<HospitalRepository>(
  (ref) => HospitalRepository(),
);
final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepository(),
);
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

final hospitalsProvider = StreamProvider<List<HospitalModel>>((ref) {
  return ref.watch(hospitalRepositoryProvider).watchHospitals();
});

final patientAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, patientId) {
      return ref
          .watch(appointmentRepositoryProvider)
          .watchPatientAppointments(patientId);
    });

final hospitalAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, hospitalId) {
      return ref
          .watch(appointmentRepositoryProvider)
          .watchHospitalAppointments(hospitalId);
    });
