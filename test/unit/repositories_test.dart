import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotsync_app/core/constants/app_constants.dart';
import 'package:slotsync_app/features/hospitals/data/repositories.dart';
import 'package:slotsync_app/shared/models/appointment_model.dart';
import 'package:slotsync_app/shared/models/support_models.dart';

void main() {
  group('AppointmentRepository', () {
    late FakeFirebaseFirestore firestore;
    late AppointmentRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = AppointmentRepository(firestore: firestore);
    });

    test(
      'bookAppointment stores the appointment and increments slot usage',
      () async {
        await firestore
            .collection(AppConstants.slotsCollection)
            .doc('slot-1')
            .set({
              'hospitalId': 'hospital-1',
              'date': DateTime(2026, 6, 20, 0, 0),
              'startTime': '09:00',
              'endTime': '09:30',
              'capacity': 2,
              'bookedCount': 0,
              'isBlocked': false,
            });

        final appointment = AppointmentModel(
          id: '',
          patientId: 'patient-1',
          hospitalId: 'hospital-1',
          appointmentDate: DateTime(2026, 6, 20, 9, 0),
          patientName: 'Pat',
          hospitalName: 'City Hospital',
          departmentId: 'dept-1',
          departmentName: 'Cardiology',
          slotId: 'slot-1',
          status: AppConstants.statusPending,
        );

        final id = await repository.bookAppointment(appointment);

        final appointmentDoc = await firestore
            .collection(AppConstants.appointmentsCollection)
            .doc(id)
            .get();
        final slotDoc = await firestore
            .collection(AppConstants.slotsCollection)
            .doc('slot-1')
            .get();

        expect(appointmentDoc.exists, isTrue);
        expect(appointmentDoc.data()?['patientId'], 'patient-1');
        expect(appointmentDoc.data()?['departmentName'], 'Cardiology');
        expect(slotDoc.data()?['bookedCount'], 1);
      },
    );

    test(
      'cancelAppointment marks appointment cancelled and decrements slot usage',
      () async {
        await firestore
            .collection(AppConstants.slotsCollection)
            .doc('slot-1')
            .set({
              'hospitalId': 'hospital-1',
              'date': DateTime(2026, 6, 20, 0, 0),
              'startTime': '09:00',
              'endTime': '09:30',
              'capacity': 2,
              'bookedCount': 1,
              'isBlocked': false,
            });

        await firestore
            .collection(AppConstants.appointmentsCollection)
            .doc('apt-1')
            .set({
              'patientId': 'patient-1',
              'hospitalId': 'hospital-1',
              'appointmentDate': DateTime(2026, 6, 20, 9, 0),
              'slotId': 'slot-1',
              'status': AppConstants.statusPending,
            });

        await repository.cancelAppointment('apt-1');

        final appointmentDoc = await firestore
            .collection(AppConstants.appointmentsCollection)
            .doc('apt-1')
            .get();
        final slotDoc = await firestore
            .collection(AppConstants.slotsCollection)
            .doc('slot-1')
            .get();

        expect(appointmentDoc.data()?['status'], AppConstants.statusCancelled);
        expect(slotDoc.data()?['bookedCount'], 0);
      },
    );

    test('patient and hospital watchers see the same status update', () async {
      await firestore
          .collection(AppConstants.appointmentsCollection)
          .doc('apt-1')
          .set({
            'patientId': 'patient-1',
            'hospitalId': 'hospital-1',
            'appointmentDate': DateTime(2026, 6, 20, 9, 0),
            'status': AppConstants.statusPending,
          });

      await repository.updateStatus('apt-1', AppConstants.statusConfirmed);

      final patientAppointments = await repository
          .watchPatientAppointments('patient-1')
          .first;
      final hospitalAppointments = await repository
          .watchHospitalAppointments('hospital-1')
          .first;

      expect(patientAppointments.single.status, AppConstants.statusConfirmed);
      expect(hospitalAppointments.single.status, AppConstants.statusConfirmed);
    });
  });

  group('ChatRepository', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepository(firestore: firestore);
    });

    test(
      'watchLatestMessage returns the newest message for a conversation',
      () async {
        await firestore.collection(AppConstants.messagesCollection).add({
          'conversationId': 'apt-1',
          'senderId': 'hospital-1',
          'text': 'Older update',
          'isRead': false,
          'createdAt': DateTime(2026, 6, 20, 9, 0),
        });
        await firestore.collection(AppConstants.messagesCollection).add({
          'conversationId': 'apt-1',
          'senderId': 'hospital-1',
          'text': 'Newest update',
          'isRead': false,
          'createdAt': DateTime(2026, 6, 20, 9, 5),
        });

        final latest = await repository.watchLatestMessage('apt-1').first;

        expect(latest?.text, 'Newest update');
      },
    );

    test(
      'markConversationAsRead updates unread incoming messages only',
      () async {
        final sentByHospital = await firestore
            .collection(AppConstants.messagesCollection)
            .add({
              'conversationId': 'apt-1',
              'senderId': 'hospital-1',
              'text': 'Please confirm.',
              'isRead': false,
              'createdAt': DateTime(2026, 6, 20, 9, 0),
            });
        final sentByPatient = await firestore
            .collection(AppConstants.messagesCollection)
            .add({
              'conversationId': 'apt-1',
              'senderId': 'patient-1',
              'text': 'Sure.',
              'isRead': false,
              'createdAt': DateTime(2026, 6, 20, 9, 1),
            });

        await repository.markConversationAsRead(
          conversationId: 'apt-1',
          currentUserId: 'patient-1',
        );

        final hospitalDoc = await sentByHospital.get();
        final patientDoc = await sentByPatient.get();

        expect(hospitalDoc.data()?['isRead'], isTrue);
        expect(patientDoc.data()?['isRead'], isFalse);
      },
    );

    test('sendMessage persists a conversation message', () async {
      await repository.sendMessage(
        const MessageModel(
          id: '',
          conversationId: 'apt-1',
          senderId: 'patient-1',
          senderName: 'Pat',
          text: 'Hello doctor',
        ),
      );

      final messages = await firestore
          .collection(AppConstants.messagesCollection)
          .where('conversationId', isEqualTo: 'apt-1')
          .get();

      expect(messages.docs, hasLength(1));
      expect(messages.docs.single.data()['text'], 'Hello doctor');
    });
  });
}
