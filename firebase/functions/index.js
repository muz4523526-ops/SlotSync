const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Send appointment reminder 24 hours before appointment.
 * Schedule: every hour via Cloud Scheduler.
 */
exports.appointmentReminders = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async () => {
    const now = new Date();
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const windowStart = new Date(tomorrow.getTime() - 30 * 60 * 1000);
    const windowEnd = new Date(tomorrow.getTime() + 30 * 60 * 1000);

    const snapshot = await db
      .collection('appointments')
      .where('status', 'in', ['pending', 'confirmed'])
      .where('appointmentDate', '>=', windowStart)
      .where('appointmentDate', '<=', windowEnd)
      .get();

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      const apt = doc.data();
      const userDoc = await db.collection('users').doc(apt.patientId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'Appointment Reminder',
            body: `Your appointment at ${apt.hospitalName} is tomorrow.`,
          },
          data: { type: 'appointment_reminder', appointmentId: doc.id },
        });
      }
      const notifRef = db.collection('notifications').doc();
      batch.set(notifRef, {
        userId: apt.patientId,
        title: 'Appointment Reminder',
        body: `Your appointment at ${apt.hospitalName} is tomorrow.`,
        type: 'appointment_reminder',
        data: { appointmentId: doc.id },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return null;
  });

/**
 * Clean up expired slots older than 30 days.
 */
exports.slotCleanup = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);

    const snapshot = await db
      .collection('slots')
      .where('date', '<', cutoff)
      .limit(500)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    return null;
  });

/**
 * Notify waitlist when a slot becomes available.
 */
exports.waitlistNotifications = functions.firestore
  .document('slots/{slotId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.bookedCount >= before.capacity && after.bookedCount < after.capacity) {
      const waitlist = await db
        .collection('waitlists')
        .where('hospitalId', '==', after.hospitalId)
        .where('status', '==', 'waiting')
        .limit(5)
        .get();

      for (const doc of waitlist.docs) {
        const entry = doc.data();
        const userDoc = await db.collection('users').doc(entry.patientId).get();
        const fcmToken = userDoc.data()?.fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'Slot Available!',
              body: 'A slot has opened up at your waitlisted hospital.',
            },
            data: { type: 'waitlist_available', slotId: context.params.slotId },
          });
        }
        await doc.ref.update({ status: 'notified' });
      }
    }
    return null;
  });

/**
 * Send booking confirmation on new appointment.
 */
exports.bookingConfirmation = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate(async (snap, context) => {
    const apt = snap.data();

    // Notify patient
    const patientDoc = await db.collection('users').doc(apt.patientId).get();
    const patientToken = patientDoc.data()?.fcmToken;
    if (patientToken) {
      await admin.messaging().send({
        token: patientToken,
        notification: {
          title: 'Booking Confirmed',
          body: `Your appointment at ${apt.hospitalName} has been booked.`,
        },
        data: { type: 'appointment_booked', appointmentId: context.params.appointmentId },
      });
    }

    // Notify hospital
    const hospitalDoc = await db.collection('users').doc(apt.hospitalId).get();
    const hospitalToken = hospitalDoc.data()?.fcmToken;
    if (hospitalToken) {
      await admin.messaging().send({
        token: hospitalToken,
        notification: {
          title: 'New Appointment',
          body: `${apt.patientName} booked an appointment.`,
        },
        data: { type: 'new_appointment', appointmentId: context.params.appointmentId },
      });
    }

    await db.collection('notifications').add({
      userId: apt.patientId,
      title: 'Booking Confirmed',
      body: `Your appointment at ${apt.hospitalName} has been booked.`,
      type: 'appointment_booked',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * Aggregate daily analytics for hospitals.
 */
exports.analyticsAggregation = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const hospitals = await db.collection('hospitals').get();
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dateKey = yesterday.toISOString().split('T')[0];

    for (const hospital of hospitals.docs) {
      const appointments = await db
        .collection('appointments')
        .where('hospitalId', '==', hospital.id)
        .where('createdAt', '>=', yesterday)
        .get();

      const completed = appointments.docs.filter(
        (d) => d.data().status === 'completed'
      ).length;
      const revenue = appointments.docs
        .filter((d) => d.data().status === 'completed')
        .reduce((sum, d) => sum + (d.data().consultationFee || 0), 0);

      await db.collection('analytics').doc(`${hospital.id}_${dateKey}`).set({
        hospitalId: hospital.id,
        date: dateKey,
        totalAppointments: appointments.size,
        completedAppointments: completed,
        revenue,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });
