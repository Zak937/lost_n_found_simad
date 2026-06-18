import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      if (!email.trim().toLowerCase().endsWith('@simad.edu.so')) {
        throw FirebaseAuthException(
            code: 'invalid-domain',
            message: 'Only SIMAD University emails (@simad.edu.so) are allowed.');
      }
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await NotificationService().initNotifications();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential?> registerWithEmail(
      String email, String password) async {
    try {
      if (!email.trim().toLowerCase().endsWith('@simad.edu.so')) {
        throw FirebaseAuthException(
            code: 'invalid-domain',
            message: 'Only SIMAD University emails (@simad.edu.so) are allowed.');
      }
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Send email verification
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }
      
      // Create default user profile in Firestore
      if (userCredential.user != null) {
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          displayName: 'SIMAD Student',
          phoneNumber: '',
        );
        await FirestoreService().createUserProfile(userModel);
      }
      
      await NotificationService().initNotifications();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
  
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      if (!email.trim().toLowerCase().endsWith('@simad.edu.so')) {
        throw FirebaseAuthException(
            code: 'invalid-domain',
            message: 'Only SIMAD University emails (@simad.edu.so) are allowed.');
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-domain':
        return e.message ?? 'Only SIMAD University emails (@simad.edu.so) are allowed.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
