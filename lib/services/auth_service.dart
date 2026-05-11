import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Register mahasiswa (role selalu 'mahasiswa')
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
      role: 'mahasiswa',
    );
    await _firestore.collection('users').doc(cred.user!.uid).set(user.toMap());
    return user;
  }

  // Login — return role setelah berhasil
  Future<String> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
    return doc.data()?['role'] ?? 'mahasiswa';
  }

  Future<void> logout() => _auth.signOut();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  // Cek role user yang sedang login
  Future<String> getCurrentRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'mahasiswa';
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'mahasiswa';
  }
}
