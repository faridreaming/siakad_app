import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';
import '../models/course_model.dart';
import '../models/krs_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── GRADES ───────────────────────────────────────────

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

  Future<void> addGrade(GradeModel grade) async {
    await _db.collection('grades').add(grade.toMap());
  }

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

  Future<void> seedCourses() async {
    final courses = [
      {
        'nama': 'Pemrograman Mobile',
        'kode': 'IF301',
        'sks': 3,
        'semester': '5',
        'dosen': 'Dr. Budi',
      },
      {
        'nama': 'Basis Data',
        'kode': 'IF201',
        'sks': 3,
        'semester': '3',
        'dosen': 'Dr. Sari',
      },
      {
        'nama': 'Algoritma & Struktur Data',
        'kode': 'IF202',
        'sks': 3,
        'semester': '3',
        'dosen': 'Dr. Andi',
      },
      {
        'nama': 'Rekayasa Perangkat Lunak',
        'kode': 'IF401',
        'sks': 3,
        'semester': '7',
        'dosen': 'Dr. Citra',
      },
      {
        'nama': 'Jaringan Komputer',
        'kode': 'IF302',
        'sks': 2,
        'semester': '5',
        'dosen': 'Dr. Deni',
      },
      {
        'nama': 'Kecerdasan Buatan',
        'kode': 'IF402',
        'sks': 3,
        'semester': '7',
        'dosen': 'Dr. Eka',
      },
    ];
    for (final c in courses) {
      await _db.collection('courses').add(c);
    }
  }

  // ─── KRS ──────────────────────────────────────────────

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

  Future<void> addKrs(KrsModel krs) async {
    // Cek duplikasi
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

  Future<void> deleteKrs(String krsId) async {
    await _db.collection('krs').doc(krsId).delete();
  }
}
