import 'package:flutter_test/flutter_test.dart';
import 'package:slotsync_app/firebase_options.dart';

void main() {
  test('Firebase options expose the expected project id', () {
    expect(AppFirebaseOptions.android.projectId, 'mediconnect-e57e7');
    expect(AppFirebaseOptions.web.projectId, 'mediconnect-e57e7');
  });
}
