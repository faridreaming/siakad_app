class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String nim;
  final String prodi;
  final String angkatan;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nim,
    required this.prodi,
    required this.angkatan,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      nim: map['nim'] ?? '',
      prodi: map['prodi'] ?? '',
      angkatan: map['angkatan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nim': nim,
      'prodi': prodi,
      'angkatan': angkatan,
    };
  }
}
