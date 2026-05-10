class GradeModel {
  final String id;
  final String uid;
  final String matkul;
  final String kode;
  final double nilai;
  final String grade;
  final int sks;
  final String semester;

  GradeModel({
    required this.id,
    required this.uid,
    required this.matkul,
    required this.kode,
    required this.nilai,
    required this.grade,
    required this.sks,
    required this.semester,
  });

  factory GradeModel.fromMap(String id, Map<String, dynamic> map) {
    return GradeModel(
      id: id,
      uid: map['uid'] ?? '',
      matkul: map['matkul'] ?? '',
      kode: map['kode'] ?? '',
      nilai: (map['nilai'] ?? 0).toDouble(),
      grade: map['grade'] ?? '',
      sks: map['sks'] ?? 0,
      semester: map['semester'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'matkul': matkul,
      'kode': kode,
      'nilai': nilai,
      'grade': grade,
      'sks': sks,
      'semester': semester,
    };
  }

  // Hitung bobot nilai untuk IP
  double get bobotNilai {
    double poin = 0;
    switch (grade) {
      case 'A':
        poin = 4.0;
        break;
      case 'A-':
        poin = 3.7;
        break;
      case 'B+':
        poin = 3.3;
        break;
      case 'B':
        poin = 3.0;
        break;
      case 'B-':
        poin = 2.7;
        break;
      case 'C+':
        poin = 2.3;
        break;
      case 'C':
        poin = 2.0;
        break;
      case 'D':
        poin = 1.0;
        break;
      default:
        poin = 0.0;
    }
    return poin * sks;
  }
}
