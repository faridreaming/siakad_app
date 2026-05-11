import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/grade_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminMahasiswaScreen extends StatelessWidget {
  const AdminMahasiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('👥 Data Mahasiswa')),
      body: StreamBuilder<List<UserModel>>(
        stream: fs.getAllMahasiswa(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada mahasiswa terdaftar.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final mhs = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      mhs.nama.isNotEmpty ? mhs.nama[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    mhs.nama,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${mhs.nim} • ${mhs.prodi}\nAngkatan ${mhs.angkatan} • ${mhs.email}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDetailMahasiswa(context, mhs, fs),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailMahasiswa(
    BuildContext context,
    UserModel mhs,
    FirestoreService fs,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    mhs.nama.isNotEmpty ? mhs.nama[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  mhs.nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  mhs.email,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 24),
              _infoRow('NIM', mhs.nim),
              _infoRow('Program Studi', mhs.prodi),
              _infoRow('Angkatan', mhs.angkatan),
              const SizedBox(height: 16),
              const Text(
                'Transkrip Nilai',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<GradeModel>>(
                future: fs.getGradesByUid(mhs.uid),
                builder: (_, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final grades = snap.data!;
                  if (grades.isEmpty) {
                    return const Text(
                      'Belum ada nilai.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  final totalSks = grades.fold(0, (s, g) => s + g.sks);
                  final totalBobot = grades.fold(
                    0.0,
                    (s, g) => s + g.bobotNilai,
                  );
                  final ipk = totalSks > 0 ? totalBobot / totalSks : 0.0;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ipkStat('IPK', ipk.toStringAsFixed(2)),
                            _ipkStat('Total SKS', '$totalSks'),
                            _ipkStat('Matkul', '${grades.length}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...grades.map(
                        (g) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              g.grade,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            g.matkul,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            'Sem ${g.semester} • ${g.sks} SKS',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            g.nilai.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _ipkStat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}
