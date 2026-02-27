import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/admin_constants.dart';

class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  bool isAdminEmail(String email) {
    return AdminConstants.adminEmails.contains(email.toLowerCase().trim());
  }

  Future<void> signIn(String email, String password) async {
    if (!isAdminEmail(email)) {
      throw Exception('Access denied. This email is not authorized as an admin.');
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
