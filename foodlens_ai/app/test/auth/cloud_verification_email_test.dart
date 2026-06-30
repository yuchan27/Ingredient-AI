import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/auth/cloud_verification_email.dart';

void main() {
  test(
    'requests Firebase verification email after refreshing a valid token',
    () async {
      var emailRequested = false;
      final sender = CloudVerificationEmailSender(
        refreshIdToken: () async => 'fresh-token',
        requestVerificationEmail: () async => emailRequested = true,
      );

      await sender.send();

      expect(emailRequested, isTrue);
    },
  );

  test(
    'rejects a missing Firebase token without claiming email success',
    () async {
      var emailRequested = false;
      final sender = CloudVerificationEmailSender(
        refreshIdToken: () async => null,
        requestVerificationEmail: () async => emailRequested = true,
      );

      await expectLater(
        sender.send(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'invalid-user-token',
          ),
        ),
      );
      expect(emailRequested, isFalse);
    },
  );
}
