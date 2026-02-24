import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  User? get currentUser => _auth.currentUser;
  
  String? _accessToken;
  String? get accessToken => _accessToken;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    if (currentUser != null) return currentUser; // Guard: Don't overwrite existing session
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint("Signed in anonymously with ID: ${userCredential.user?.uid}");
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
      return null;
    }
  }

  // Restore session and tokens on startup
  Future<void> initializeSession() async {
    if (currentUser != null && !currentUser!.isAnonymous) {
      await signInSilently();
    } else if (currentUser == null) {
      await signInAnonymously();
    }
  }

  Future<void> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        _accessToken = googleAuth.accessToken;
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error silent sign-in: $e");
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      _accessToken = googleAuth.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _accessToken = null;
    notifyListeners();
  }
}
