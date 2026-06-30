import 'package:firebase_auth/firebase_auth.dart';

typedef RefreshIdToken = Future<String?> Function();
typedef RequestVerificationEmail = Future<void> Function();

class CloudVerificationEmailSender {
  const CloudVerificationEmailSender({
    required this.refreshIdToken,
    required this.requestVerificationEmail,
  });

  final RefreshIdToken refreshIdToken;
  final RequestVerificationEmail requestVerificationEmail;

  Future<void> send() async {
    final token = await refreshIdToken();
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-user-token');
    }
    await requestVerificationEmail();
  }
}
