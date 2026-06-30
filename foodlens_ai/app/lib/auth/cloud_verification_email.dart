import 'package:firebase_auth/firebase_auth.dart';

typedef RefreshIdToken = Future<String?> Function();
typedef ConfigureLanguage = Future<void> Function(String languageCode);
typedef RequestVerificationEmail = Future<void> Function();

class CloudVerificationEmailSender {
  const CloudVerificationEmailSender({
    required this.refreshIdToken,
    required this.configureLanguage,
    required this.requestVerificationEmail,
    this.languageCode = 'zh-TW',
  });

  final RefreshIdToken refreshIdToken;
  final ConfigureLanguage configureLanguage;
  final RequestVerificationEmail requestVerificationEmail;
  final String languageCode;

  Future<void> send() async {
    final token = await refreshIdToken();
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-user-token');
    }
    await configureLanguage(languageCode);
    await requestVerificationEmail();
  }
}
