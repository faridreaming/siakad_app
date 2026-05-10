import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/grade_model.dart';
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

  String _gradeColor(String grade) {
    switch (grade) {
      case 'A':
      case 'A-':
        return 'A';
      case 'B+':
      case 'B':
      case 'B-':
        return 'B';
      case 'C+':
      case 'C':
        return 'C';
      default:
        return 'D';
    }
  }

  Color _getGradeColor(String grade) {
    switch (_gradeColor(grade)) {
      case 'A':
        return AppTheme.success;
      case 'B':
        return AppTheme.primary;
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
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf', child: Text('📄 Export PDF')),
              const PopupMenuItem(
                value: 'email',
                child: Text('📧 Kirim Email'),
              ),
            ],
            onSelected: (val) async {
              final grades = await _fsService
                  .getGrades(uid, semester: _selectedSemester)
                  .first;
              if (val == 'pdf' && widget.user != null) {
                await PdfService.generateKHS(
                  user: widget.user!,
                  grades: grades,
                  semester: _selectedSemester,
                );
              } else if (val == 'email' && widget.user != null) {
                for (final g in grades) {
                  await EmailService.sendNilaiNotification(
                    toEmail: widget.user!.email,
                    namaMahasiswa: widget.user!.nama,
                    matkul: g.matkul,
                    nilai: g.nilai.toStringAsFixed(0),
                    grade: g.grade,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email terkirim!')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Semester
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _semesters
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s == 'Semua' ? 'Semua' : 'Sem $s'),
                          selected: _selectedSemester == s,
                          onSelected: (_) =>
                              setState(() => _selectedSemester = s),
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Grades List
          Expanded(
            child: StreamBuilder<List<GradeModel>>(
              stream: _fsService.getGrades(uid, semester: _selectedSemester),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final grades = snapshot.data!;
                if (grades.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grade_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada nilai',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                int totalSks = grades.fold(0, (s, g) => s + g.sks);
                double totalBobot = grades.fold(
                  0.0,
                  (s, g) => s + g.bobotNilai,
                );
                double ip = totalSks > 0 ? totalBobot / totalSks : 0;

                return Column(
                  children: [
                    // IP Summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: AppTheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ipStat('IP', ip.toStringAsFixed(2)),
                              _ipStat('SKS', '$totalSks'),
                              _ipStat('Matkul', '${grades.length}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: grades.length,
                        itemBuilder: (_, i) {
                          final g = grades[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getGradeColor(g.grade),
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
                                    '${g.nilai.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGradeDialog(context, uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _ipStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  void _showAddGradeDialog(BuildContext context, String uid) {
    final matkulCtrl = TextEditingController();
    final kodeCtrl = TextEditingController();
    final nilaiCtrl = TextEditingController();
    String grade = 'A';
    int sks = 3;
    String semester = '1';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Nilai'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matkulCtrl,
                decoration: const InputDecoration(labelText: 'Mata Kuliah'),
              ),
              TextField(
                controller: kodeCtrl,
                decoration: const InputDecoration(labelText: 'Kode'),
              ),
              TextField(
                controller: nilaiCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
              ),
              DropdownButtonFormField<String>(
                value: grade,
                decoration: const InputDecoration(labelText: 'Grade'),
                items: ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => grade = v!,
              ),
              DropdownButtonFormField<int>(
                value: sks,
                decoration: const InputDecoration(labelText: 'SKS'),
                items: [1, 2, 3, 4]
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (v) => sks = v!,
              ),
              DropdownButtonFormField<String>(
                value: semester,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: ['1', '2', '3', '4', '5', '6', '7', '8']
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('Semester $s'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => semester = v!,
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
              final newGrade = GradeModel(
                id: '',
                uid: uid,
                matkul: matkulCtrl.text,
                kode: kodeCtrl.text,
                nilai: double.tryParse(nilaiCtrl.text) ?? 0,
                grade: grade,
                sks: sks,
                semester: semester,
              );
              await _fsService.addGrade(newGrade);

              // Kirim email notifikasi
              if (widget.user != null) {
                EmailService.sendNilaiNotification(
                  toEmail: widget.user!.email,
                  namaMahasiswa: widget.user!.nama,
                  matkul: matkulCtrl.text,
                  nilai: nilaiCtrl.text,
                  grade: grade,
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
