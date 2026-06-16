import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router/app_router.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'shared/providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'core/constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Only initialize if not already done
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase only once
  try {
    await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized, ignore
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  runApp(const ProviderScope(child: SlotSyncApp()));
}

class SlotSyncApp extends ConsumerWidget {
  const SlotSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
