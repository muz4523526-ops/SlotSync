import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/patient_shell.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/hospitals/presentation/search_screen.dart';
import '../../features/hospitals/presentation/hospital_detail_screen.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/appointments/presentation/booking_screen.dart';
import '../../features/chat/presentation/messages_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/support/presentation/help_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_appointments_screen.dart';
import '../../features/admin/presentation/admin_services_screen.dart';
import '../../features/admin/presentation/admin_slots_screen.dart';
import '../../features/admin/presentation/admin_profile_screen.dart';
import '../../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAuth = state.matchedLocation.startsWith('/auth');

      if (isSplash) return null;

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;

      if (!onboardingDone && !isOnboarding) return '/onboarding';

      final user = authState.valueOrNull;
      if (user == null && !isAuth && !isOnboarding) return '/auth/login';

      if (user != null && !isAuth && !isOnboarding && !isSplash) {
        final isOnAdmin = state.matchedLocation.startsWith('/admin');
        try {
          final role = await ref.read(authRepositoryProvider).getUserRole(user.uid);
          if (role == AppConstants.roleHospital && !isOnAdmin) {
            return '/admin';
          }
          if (role != AppConstants.roleHospital && isOnAdmin) {
            return '/home';
          }
        } catch (_) {
          // Role fetch failed — allow current route
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (_, _, child) => PatientShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(
            path: '/appointments',
            builder: (_, _) => const AppointmentsScreen(),
          ),
          GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/hospital/:id',
        builder: (_, state) =>
            HospitalDetailScreen(hospitalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:hospitalId',
        builder: (_, state) => BookingScreen(
          hospitalId: state.pathParameters['hospitalId']!,
          serviceId: state.uri.queryParameters['serviceId'],
          departmentId: state.uri.queryParameters['departmentId'],
        ),
      ),
      GoRoute(
        path: '/booking-success/:appointmentId',
        builder: (_, state) => BookingSuccessScreen(
          appointmentId: state.pathParameters['appointmentId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
          title: state.uri.queryParameters['title'] ?? 'Chat',
        ),
      ),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      ShellRoute(
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/appointments',
            builder: (_, _) => const AdminAppointmentsScreen(),
          ),
          GoRoute(
            path: '/admin/services',
            builder: (_, _) => const AdminServicesScreen(),
          ),
          GoRoute(
            path: '/admin/slots',
            builder: (_, _) => const AdminSlotsScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, _) => const AdminProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
