import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _fs = FirestoreService();
  String _filterSemester = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📚 Kelola Mata Kuliah')),
      body: Column(
        children: [
          // Filter semester
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['Semua', '1', '2', '3', '4', '5', '6', '7', '8']
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s == 'Semua' ? 'Semua' : 'Sem $s'),
                        selected: _filterSemester == s,
                        onSelected: (_) => setState(() => _filterSemester = s),
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: _fs.getCourses(semester: _filterSemester),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final courses = snap.data!;
                if (courses.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada mata kuliah.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (_, i) {
                    final c = courses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            c.kode.length >= 2
                                ? c.kode.substring(0, 2)
                                : c.kode,
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        title: Text(
                          c.nama,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${c.kode} • ${c.sks} SKS • Sem ${c.semester}\n${c.dosen}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primary,
                              ),
                              onPressed: () =>
                                  _showCourseDialog(context, course: c),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, c.id, c.nama),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Matkul'),
      ),
    );
  }

  void _showCourseDialog(BuildContext context, {CourseModel? course}) {
    final namaCtrl = TextEditingController(text: course?.nama ?? '');
    final kodeCtrl = TextEditingController(text: course?.kode ?? '');
    final dosenCtrl = TextEditingController(text: course?.dosen ?? '');
    int sks = course?.sks ?? 3;
    String semester = course?.semester ?? '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(
            course == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Mata Kuliah',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: kodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kode (contoh: IF301)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dosenCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Dosen'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: sks,
                  decoration: const InputDecoration(labelText: 'SKS'),
                  items: [1, 2, 3, 4]
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s, child: Text('$s SKS')),
                      )
                      .toList(),
                  onChanged: (v) => setInner(() => sks = v!),
                ),
                const SizedBox(height: 8),
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
                  onChanged: (v) => setInner(() => semester = v!),
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
                final newCourse = CourseModel(
                  id: course?.id ?? '',
                  nama: namaCtrl.text.trim(),
                  kode: kodeCtrl.text.trim().toUpperCase(),
                  sks: sks,
                  semester: semester,
                  dosen: dosenCtrl.text.trim(),
                );
                if (course == null) {
                  await _fs.addCourse(newCourse);
                } else {
                  await _fs.updateCourse(course.id, newCourse);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(course == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await _fs.deleteCourse(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
