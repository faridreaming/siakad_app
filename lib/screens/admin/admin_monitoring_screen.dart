import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/grade_model.dart';
import '../../models/krs_model.dart';
import '../../theme/app_theme.dart';

class AdminMonitoringScreen extends StatelessWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Monitoring Akademik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat Cards ─────────────────────────────────
            StreamBuilder<List<UserModel>>(
              stream: fs.getAllMahasiswa(),
              builder: (_, snapU) {
                return StreamBuilder<List<GradeModel>>(
                  stream: fs.getAllGrades(),
                  builder: (_, snapG) {
                    return StreamBuilder<List<KrsModel>>(
                      stream: fs.getAllKrs(),
                      builder: (_, snapK) {
                        final totalMhs = snapU.data?.length ?? 0;
                        final totalNilai = snapG.data?.length ?? 0;
                        final pendingKrs =
                            snapK.data
                                ?.where((k) => k.status == 'pending')
                                .length ??
                            0;

                        // Hitung rata-rata IPK
                        double avgIpk = 0;
                        if (snapU.hasData && snapG.hasData) {
                          final grades = snapG.data!;
                          final grouped = <String, List<GradeModel>>{};
                          for (final g in grades) {
                            grouped.putIfAbsent(g.uid, () => []).add(g);
                          }
                          if (grouped.isNotEmpty) {
                            double total = 0;
                            for (final entry in grouped.entries) {
                              final gs = entry.value;
                              final sks = gs.fold(0, (s, g) => s + g.sks);
                              final bobot = gs.fold(
                                0.0,
                                (s, g) => s + g.bobotNilai,
                              );
                              total += sks > 0 ? bobot / sks : 0;
                            }
                            avgIpk = total / grouped.length;
                          }
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                _StatCard(
                                  'Total Mahasiswa',
                                  '$totalMhs',
                                  Icons.people,
                                  AppTheme.primary,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  'Rata-rata IPK',
                                  avgIpk.toStringAsFixed(2),
                                  Icons.star,
                                  AppTheme.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _StatCard(
                                  'Total Nilai',
                                  '$totalNilai',
                                  Icons.grade,
                                  AppTheme.success,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  'KRS Pending',
                                  '$pendingKrs',
                                  Icons.pending_actions,
                                  AppTheme.error,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Daftar Mahasiswa + IPK ──────────────────────
            const Text(
              'Rekap IPK Mahasiswa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<UserModel>>(
              stream: fs.getAllMahasiswa(),
              builder: (_, snapU) {
                if (!snapU.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final mahasiswaList = snapU.data!;
                if (mahasiswaList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada mahasiswa terdaftar.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mahasiswaList.length,
                  itemBuilder: (_, i) {
                    final mhs = mahasiswaList[i];
                    return FutureBuilder<List<GradeModel>>(
                      future: fs.getGradesByUid(mhs.uid),
                      builder: (_, snapG) {
                        final grades = snapG.data ?? [];
                        final totalSks = grades.fold(0, (s, g) => s + g.sks);
                        final totalBobot = grades.fold(
                          0.0,
                          (s, g) => s + g.bobotNilai,
                        );
                        final ipk = totalSks > 0 ? totalBobot / totalSks : 0.0;
                        final ipkColor = ipk >= 3.5
                            ? AppTheme.success
                            : ipk >= 2.75
                            ? AppTheme.primary
                            : ipk >= 2.0
                            ? AppTheme.warning
                            : AppTheme.error;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                mhs.nama.isNotEmpty
                                    ? mhs.nama[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              mhs.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${mhs.nim} • ${mhs.prodi} • Angkatan ${mhs.angkatan}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ipk.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ipkColor,
                                  ),
                                ),
                                const Text(
                                  'IPK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
