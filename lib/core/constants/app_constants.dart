class AppConstants {
  AppConstants._();

  static const appName = 'SlotSync';
  static const tagline = 'Your health. Your time. Simplified.';

  // Firestore collections
  static const usersCollection = 'users';
  static const hospitalsCollection = 'hospitals';
  static const departmentsCollection = 'departments';
  static const servicesCollection = 'services';
  static const appointmentsCollection = 'appointments';
  static const slotsCollection = 'slots';
  static const reviewsCollection = 'reviews';
  static const messagesCollection = 'messages';
  static const notificationsCollection = 'notifications';
  static const waitlistsCollection = 'waitlists';
  static const documentsCollection = 'documents';
  static const analyticsCollection = 'analytics';

  // Roles
  static const rolePatient = 'patient';
  static const roleHospital = 'hospital';
  static const roleAdmin = 'admin';

  // Appointment statuses
  static const statusPending = 'pending';
  static const statusConfirmed = 'confirmed';
  static const statusCompleted = 'completed';
  static const statusCancelled = 'cancelled';
  static const statusRescheduled = 'rescheduled';

  // Shared prefs keys
  static const onboardingCompleteKey = 'onboarding_complete';
  static const fcmTokenKey = 'fcm_token';
}
