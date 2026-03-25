import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      return await _createOrGetUser(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithApple() async {
    try {
      final provider = AppleAuthProvider();
      provider.addScope('email');
      provider.addScope('name');

      final userCredential = await _auth.signInWithProvider(provider);
      final user = userCredential.user!;

      return await _createOrGetUser(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> _createOrGetUser(User firebaseUser) async {
    final docRef = _db.collection(AppConstants.colUsers).doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // New user
    final now = DateTime.now();
    final newUser = UserModel(
      id: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'Pilot',
      photoUrl: firebaseUser.photoURL,
      language: 'tr',
      dailyGamesResetAt: now,
      jokerResetAt: now,
      createdAt: now,
    );

    await docRef.set(newUser.toFirestore());
    return newUser;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection(AppConstants.colUsers).doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }
}
