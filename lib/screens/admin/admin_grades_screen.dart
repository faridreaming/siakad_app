import 'package:flutter/material.dart';
import '../../models/grade_model.dart';
import '../../models/user_model.dart';
import '../../models/krs_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminGradesScreen extends StatefulWidget {
  const AdminGradesScreen({super.key});

  @override
  State<AdminGradesScreen> createState() => _AdminGradesScreenState();
}

class _AdminGradesScreenState extends State<AdminGradesScreen> {
  final _fs = FirestoreService();
  UserModel? _selectedMhs;
  List<UserModel> _mahasiswaList = [];

  @override
  void initState() {
    super.initState();
    _fs.getAllMahasiswa().listen((list) {
      if (mounted)
        setState(() {
          _mahasiswaList = list;
          _selectedMhs ??= list.isNotEmpty ? list.first : null;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Input Nilai')),
      body: Column(
        children: [
          // Pilih mahasiswa
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<UserModel>(
              value: _selectedMhs,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih Mahasiswa',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: _mahasiswaList
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        '${m.nama} (${m.nim})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedMhs = v),
            ),
          ),

          // Daftar nilai mahasiswa terpilih
          Expanded(
            child: _selectedMhs == null
                ? const Center(
                    child: Text(
                      'Pilih mahasiswa terlebih dahulu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<List<GradeModel>>(
                    stream: _fs.getGrades(_selectedMhs!.uid),
                    builder: (_, snap) {
                      if (!snap.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final grades = snap.data!;
                      if (grades.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.grade_outlined,
                                size: 56,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada nilai.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Input Nilai'),
                                onPressed: () => _showInputNilaiDialog(
                                  context,
                                  _selectedMhs!,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${g.nilai.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showEditNilaiDialog(context, g),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _fs.deleteGrade(g.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedMhs == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showInputNilaiDialog(context, _selectedMhs!),
              icon: const Icon(Icons.add),
              label: const Text('Input Nilai'),
            ),
    );
  }

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

  void _showInputNilaiDialog(BuildContext context, UserModel mhs) async {
    // Ambil KRS mahasiswa ini
    final krsList = await _fs.getKrsByUid(mhs.uid);
    final existingGrades = await _fs.getGrades(mhs.uid).first;
    final gradedKodes = existingGrades
        .map((g) => '${g.kode}_${g.semester}')
        .toSet();
    final available = krsList
        .where((k) => !gradedKodes.contains('${k.kode}_${k.semester}'))
        .toList();

    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua KRS mahasiswa ini sudah dinilai.')),
      );
      return;
    }

    KrsModel? selectedKrs = available.first;
    final nilaiCtrl = TextEditingController();
    String grade = 'A';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Input Nilai — ${mhs.nama}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<KrsModel>(
                value: selectedKrs,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mata Kuliah (dari KRS)',
                ),
                items: available
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
              const SizedBox(height: 8),
              TextField(
                controller: nilaiCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nilai Angka (0–100)',
                ),
                onChanged: (v) {
                  final n = double.tryParse(v) ?? 0;
                  setInner(() => grade = _nilaiToGrade(n));
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: grade,
                decoration: const InputDecoration(labelText: 'Grade'),
                items: ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setInner(() => grade = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedKrs == null || nilaiCtrl.text.isEmpty) return;
                await _fs.addGrade(
                  GradeModel(
                    id: '',
                    uid: mhs.uid,
                    matkul: selectedKrs!.namaMatkul,
                    kode: selectedKrs!.kode,
                    nilai: double.tryParse(nilaiCtrl.text) ?? 0,
                    grade: grade,
                    sks: selectedKrs!.sks,
                    semester: selectedKrs!.semester,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNilaiDialog(BuildContext context, GradeModel grade) {
    final nilaiCtrl = TextEditingController(
      text: grade.nilai.toStringAsFixed(0),
    );
    String selectedGrade = grade.grade;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Edit Nilai — ${grade.matkul}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nilaiCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nilai Angka (0–100)',
                ),
                onChanged: (v) {
                  final n = double.tryParse(v) ?? 0;
                  setInner(() => selectedGrade = _nilaiToGrade(n));
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'Grade'),
                items: ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setInner(() => selectedGrade = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = GradeModel(
                  id: grade.id,
                  uid: grade.uid,
                  matkul: grade.matkul,
                  kode: grade.kode,
                  nilai: double.tryParse(nilaiCtrl.text) ?? 0,
                  grade: selectedGrade,
                  sks: grade.sks,
                  semester: grade.semester,
                );
                await _fs.updateGrade(grade.id, updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Update'),
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
