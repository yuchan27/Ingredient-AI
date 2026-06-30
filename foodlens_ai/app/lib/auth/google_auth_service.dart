import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

bool get googleSignInConfigured => googleServerClientId.isNotEmpty;

class GoogleAuthService {
  GoogleAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  static Future<void>? _initialization;

  Future<UserCredential> signIn() async {
    if (!googleSignInConfigured) {
      throw FirebaseAuthException(code: 'google-sign-in-not-configured');
    }

    final googleSignIn = GoogleSignIn.instance;
    _initialization ??= googleSignIn.initialize(
      serverClientId: googleServerClientId,
    );
    await _initialization;

    final googleUser = await googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-google-id-token');
    }

    return _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }
}
