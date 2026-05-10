class CourseModel {
  final String id;
  final String nama;
  final String kode;
  final int sks;
  final String semester;
  final String dosen;

  CourseModel({
    required this.id,
    required this.nama,
    required this.kode,
    required this.sks,
    required this.semester,
    required this.dosen,
  });

  factory CourseModel.fromMap(String id, Map<String, dynamic> map) {
    return CourseModel(
      id: id,
      nama: map['nama'] ?? '',
      kode: map['kode'] ?? '',
      sks: map['sks'] ?? 0,
      semester: map['semester'] ?? '',
      dosen: map['dosen'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kode': kode,
      'sks': sks,
      'semester': semester,
      'dosen': dosen,
    };
  }
}
