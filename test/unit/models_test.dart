import 'package:flutter_test/flutter_test.dart';
import 'package:slotsync_app/core/constants/app_constants.dart';
import 'package:slotsync_app/shared/models/appointment_model.dart';
import 'package:slotsync_app/shared/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap creates patient user correctly', () {
      final user = UserModel.fromMap({
        'email': 'test@example.com',
        'name': 'John Doe',
        'role': 'patient',
      }, id: 'user1');

      expect(user.id, 'user1');
      expect(user.email, 'test@example.com');
      expect(user.isPatient, isTrue);
      expect(user.isHospital, isFalse);
    });

    test('toMap includes required fields', () {
      final user = UserModel(
        id: 'user1',
        email: 'test@example.com',
        name: 'John',
        role: AppConstants.rolePatient,
      );

      final map = user.toMap();
      expect(map['email'], 'test@example.com');
      expect(map['role'], 'patient');
    });
  });

  group('SlotModel', () {
    test('isAvailable returns true when not blocked and has capacity', () {
      final slot = SlotModel(
        id: 'slot1',
        hospitalId: 'h1',
        date: DateTime.now(),
        startTime: '09:00',
        endTime: '09:30',
        capacity: 2,
        bookedCount: 1,
      );

      expect(slot.isAvailable, isTrue);
      expect(slot.remaining, 1);
    });

    test('isAvailable returns false when full', () {
      final slot = SlotModel(
        id: 'slot1',
        hospitalId: 'h1',
        date: DateTime.now(),
        startTime: '09:00',
        endTime: '09:30',
        capacity: 1,
        bookedCount: 1,
      );

      expect(slot.isAvailable, isFalse);
    });
  });

  group('AppointmentModel', () {
    test('isUpcoming for future confirmed appointment', () {
      final apt = AppointmentModel(
        id: 'apt1',
        patientId: 'p1',
        hospitalId: 'h1',
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        status: AppConstants.statusConfirmed,
      );

      expect(apt.isUpcoming, isTrue);
    });
  });
}
