import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotsync_app/core/errors/app_exception.dart';
import 'package:slotsync_app/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository Google sign-in platform support', () {
    test('supports web even when the host platform is Windows', () {
      expect(
        AuthRepository.isGoogleSignInSupported(
          isWeb: true,
          platform: TargetPlatform.windows,
        ),
        isTrue,
      );
    });

    test('does not support Google sign-in on Windows builds', () {
      expect(
        AuthRepository.isGoogleSignInSupported(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
        isFalse,
      );
    });

    test('returns a helpful Windows message', () {
      expect(
        AuthRepository.unsupportedGoogleSignInMessage(
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
        contains('Windows'),
      );
    });
  });

  group('AuthRepository Google sign-in error mapping', () {
    test('maps Android OAuth developer error to a setup hint', () {
      final exception = AuthRepository.mapGoogleSignInErrorForTest(
        PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 10:',
        ),
      );

      expect(exception, isA<AuthException>());
      expect(exception.message, contains('SHA-1/SHA-256'));
      expect(exception.message, contains('google-services.json'));
    });

    test('maps unsupported platform errors to a clearer auth exception', () {
      final exception = AuthRepository.mapGoogleSignInErrorForTest(
        PlatformException(
          code: 'unsupported',
          message: 'Google sign in is unsupported on this platform',
        ),
        platform: TargetPlatform.windows,
      );

      expect(exception, isA<AuthException>());
      expect(exception.message, isNotEmpty);
    });
  });
}
