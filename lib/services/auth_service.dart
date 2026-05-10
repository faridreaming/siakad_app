import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Register
  Future<UserModel?> register({
    required String email,
    required String password,
    required String nama,
    required String nim,
    required String prodi,
    required String angkatan,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      nama: nama,
      email: email,
      nim: nim,
      prodi: prodi,
      angkatan: angkatan,
    );

    await _firestore.collection('users').doc(cred.user!.uid).set(user.toMap());

    return user;
  }

  // Login
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // Logout
  Future<void> logout() => _auth.signOut();

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }
}
