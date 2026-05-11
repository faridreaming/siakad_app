import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';
import '../models/course_model.dart';
import '../models/krs_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── COURSES ──────────────────────────────────────────

  Stream<List<CourseModel>> getCourses({String? semester}) {
    Query query = _db.collection('courses');
    if (semester != null && semester != 'Semua') {
      query = query.where('semester', isEqualTo: semester);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => CourseModel.fromMap(d.id, d.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<void> addCourse(CourseModel course) async {
    await _db.collection('courses').add(course.toMap());
  }

  Future<void> updateCourse(String id, CourseModel course) async {
    await _db.collection('courses').doc(id).update(course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    await _db.collection('courses').doc(id).delete();
  }

  // ─── GRADES ──────────────────────────────────────────

  Stream<List<GradeModel>> getGrades(String uid, {String? semester}) {
    Query query = _db.collection('grades').where('uid', isEqualTo: uid);
    if (semester != null && semester != 'Semua') {
      query = query.where('semester', isEqualTo: semester);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => GradeModel.fromMap(d.id, d.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  // Ambil semua grades (untuk admin monitoring)
  Stream<List<GradeModel>> getAllGrades() {
    return _db
        .collection('grades')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    GradeModel.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<void> addGrade(GradeModel grade) async {
    await _db.collection('grades').add(grade.toMap());
  }

  Future<void> updateGrade(String id, GradeModel grade) async {
    await _db.collection('grades').doc(id).update(grade.toMap());
  }

  Future<void> deleteGrade(String id) async {
    await _db.collection('grades').doc(id).delete();
  }

  // ─── KRS ─────────────────────────────────────────────

  Stream<List<KrsModel>> getKrs(String uid, String semester) {
    return _db
        .collection('krs')
        .where('uid', isEqualTo: uid)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => KrsModel.fromMap(d.id, d.data())).toList(),
        );
  }

  // Semua KRS (admin)
  Stream<List<KrsModel>> getAllKrs({String? status}) {
    Query query = _db.collection('krs');
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => KrsModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> addKrs(KrsModel krs) async {
    final existing = await _db
        .collection('krs')
        .where('uid', isEqualTo: krs.uid)
        .where('courseId', isEqualTo: krs.courseId)
        .where('semester', isEqualTo: krs.semester)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Mata kuliah sudah ada di KRS!');
    }
    await _db.collection('krs').add(krs.toMap());
  }

  Future<void> updateKrsStatus(String krsId, String status) async {
    await _db.collection('krs').doc(krsId).update({'status': status});
  }

  Future<void> deleteKrs(String krsId) async {
    await _db.collection('krs').doc(krsId).delete();
  }

  // ─── USERS (admin) ────────────────────────────────────

  Stream<List<UserModel>> getAllMahasiswa() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'mahasiswa')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => UserModel.fromMap(d.data())).toList(),
        );
  }

  Future<List<GradeModel>> getGradesByUid(String uid) async {
    final snap = await _db
        .collection('grades')
        .where('uid', isEqualTo: uid)
        .get();
    return snap.docs.map((d) => GradeModel.fromMap(d.id, d.data())).toList();
  }

  Future<List<KrsModel>> getKrsByUid(String uid) async {
    final snap = await _db.collection('krs').where('uid', isEqualTo: uid).get();
    return snap.docs.map((d) => KrsModel.fromMap(d.id, d.data())).toList();
  }
}
