class KrsModel {
  final String id;
  final String uid;
  final String courseId;
  final String namaMatkul;
  final String kode;
  final int sks;
  final String semester;
  final String status; // 'pending', 'approved', 'rejected'

  KrsModel({
    required this.id,
    required this.uid,
    required this.courseId,
    required this.namaMatkul,
    required this.kode,
    required this.sks,
    required this.semester,
    required this.status,
  });

  factory KrsModel.fromMap(String id, Map<String, dynamic> map) {
    return KrsModel(
      id: id,
      uid: map['uid'] ?? '',
      courseId: map['courseId'] ?? '',
      namaMatkul: map['namaMatkul'] ?? '',
      kode: map['kode'] ?? '',
      sks: map['sks'] ?? 0,
      semester: map['semester'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'courseId': courseId,
      'namaMatkul': namaMatkul,
      'kode': kode,
      'sks': sks,
      'semester': semester,
      'status': status,
    };
  }
}
