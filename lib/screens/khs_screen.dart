import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/grade_model.dart';
import '../models/krs_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../services/email_service.dart';
import '../theme/app_theme.dart';

class KhsScreen extends StatefulWidget {
  final UserModel? user;
  const KhsScreen({super.key, this.user});

  @override
  State<KhsScreen> createState() => _KhsScreenState();
}

class _KhsScreenState extends State<KhsScreen> {
  final _fsService = FirestoreService();
  String _selectedSemester = 'Semua';
  final List<String> _semesters = [
    'Semua',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
      case 'A-':
        return AppTheme.success;
      case 'B+':
      case 'B':
      case 'B-':
        return AppTheme.primary;
      case 'C+':
      case 'C':
        return AppTheme.warning;
      default:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KHS - Kartu Hasil Studi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('📄 Export PDF')),
              PopupMenuItem(value: 'email', child: Text('📧 Kirim Email')),
            ],
            onSelected: (val) async {
              final grades = await _fsService
                  .getGrades(uid, semester: _selectedSemester)
                  .first;
              if (grades.isEmpty) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Belum ada data nilai!')),
                  );
                return;
              }
              if (val == 'pdf' && widget.user != null) {
                await PdfService.generateKHS(
                  user: widget.user!,
                  grades: grades,
                  semester: _selectedSemester,
                );
              } else if (val == 'email' && widget.user != null) {
                bool allOk = true;
                for (final g in grades) {
                  final ok = await EmailService.sendNilaiNotification(
                    toEmail: widget.user!.email,
                    namaMahasiswa: widget.user!.nama,
                    matkul: g.matkul,
                    nilai: g.nilai.toStringAsFixed(0),
                    grade: g.grade,
                  );
                  if (!ok) allOk = false;
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        allOk
                            ? '✅ Email berhasil dikirim!'
                            : '⚠️ Sebagian email gagal. Cek konfigurasi SMTP.',
                      ),
                      backgroundColor: allOk
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Semester ────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _semesters
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s == 'Semua' ? 'Semua' : 'Sem $s'),
                        selected: _selectedSemester == s,
                        onSelected: (_) =>
                            setState(() => _selectedSemester = s),
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                        checkmarkColor: AppTheme.primary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Grades List ────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<GradeModel>>(
              stream: _fsService.getGrades(uid, semester: _selectedSemester),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final grades = snapshot.data ?? [];

                if (grades.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.grade_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada nilai',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tambah nilai dari mata kuliah\nyang sudah diambil di KRS',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Nilai'),
                          onPressed: () => _showAddGradeFromKRS(context, uid),
                        ),
                      ],
                    ),
                  );
                }

                final totalSks = grades.fold(0, (s, g) => s + g.sks);
                final totalBobot = grades.fold(0.0, (s, g) => s + g.bobotNilai);
                final ip = totalSks > 0 ? totalBobot / totalSks : 0.0;

                return Column(
                  children: [
                    // IP Summary Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Card(
                        color: AppTheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ipStat('IP', ip.toStringAsFixed(2)),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white30,
                              ),
                              _ipStat('Total SKS', '$totalSks'),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white30,
                              ),
                              _ipStat('Matkul', '${grades.length}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: grades.length,
                        itemBuilder: (_, i) {
                          final g = grades[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _gradeColor(g.grade),
                                child: Text(
                                  g.grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                g.matkul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${g.kode} • Sem ${g.semester} • ${g.sks} SKS',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    g.nilai.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _gradeColor(g.grade),
                                    ),
                                  ),
                                  const Text(
                                    'Nilai',
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
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGradeFromKRS(context, uid),
        icon: const Icon(Icons.add),
        label: const Text('Input Nilai'),
      ),
    );
  }

  Widget _ipStat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );

  // ── Tambah nilai dari KRS yang sudah diambil ─────────────
  void _showAddGradeFromKRS(BuildContext context, String uid) async {
    // Ambil semua KRS mahasiswa ini
    final allKrs = <KrsModel>[];
    for (final sem in ['1', '2', '3', '4', '5', '6', '7', '8']) {
      final list = await _fsService.getKrs(uid, sem).first;
      allKrs.addAll(list);
    }

    // Filter: yang belum ada nilainya
    final existingGrades = await _fsService.getGrades(uid).first;
    final gradedKodes = existingGrades
        .map((g) => '${g.kode}_${g.semester}')
        .toSet();
    final availableKrs = allKrs
        .where((k) => !gradedKodes.contains('${k.kode}_${k.semester}'))
        .toList();

    if (!mounted) return;

    if (availableKrs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Semua mata kuliah KRS sudah ada nilainya, atau KRS masih kosong.',
          ),
        ),
      );
      return;
    }

    KrsModel? selectedKrs = availableKrs.first;
    final nilaiCtrl = TextEditingController();
    String grade = 'A';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Input Nilai'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mata Kuliah (dari KRS)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<KrsModel>(
                  value: selectedKrs,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: availableKrs
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text(
                            '${k.namaMatkul} (Sem ${k.semester})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setInner(() => selectedKrs = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nilaiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nilai Angka (0–100)',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    // Auto-convert nilai ke grade
                    final n = double.tryParse(v) ?? 0;
                    setInner(() => grade = _nilaiToGrade(n));
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: grade,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    isDense: true,
                  ),
                  items: ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setInner(() => grade = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedKrs == null || nilaiCtrl.text.isEmpty) {
                  return;
                }
                final newGrade = GradeModel(
                  id: '',
                  uid: uid,
                  matkul: selectedKrs!.namaMatkul,
                  kode: selectedKrs!.kode,
                  nilai: double.tryParse(nilaiCtrl.text) ?? 0,
                  grade: grade,
                  sks: selectedKrs!.sks,
                  semester: selectedKrs!.semester,
                );
                await _fsService.addGrade(newGrade);

                // Email notifikasi otomatis
                if (widget.user != null) {
                  EmailService.sendNilaiNotification(
                    toEmail: widget.user!.email,
                    namaMahasiswa: widget.user!.nama,
                    matkul: selectedKrs!.namaMatkul,
                    nilai: nilaiCtrl.text,
                    grade: grade,
                  );
                }

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Nilai berhasil disimpan!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  String _nilaiToGrade(double nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 80) return 'A-';
    if (nilai >= 75) return 'B+';
    if (nilai >= 70) return 'B';
    if (nilai >= 65) return 'B-';
    if (nilai >= 60) return 'C+';
    if (nilai >= 55) return 'C';
    if (nilai >= 40) return 'D';
    return 'E';
  }
}
