import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/krs_model.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class KrsScreen extends StatefulWidget {
  final UserModel? user;
  const KrsScreen({super.key, this.user});

  @override
  State<KrsScreen> createState() => _KrsScreenState();
}

class _KrsScreenState extends State<KrsScreen> {
  final _fsService = FirestoreService();
  String _semester = '5';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KRS - Rencana Studi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final krsList = await _fsService.getKrs(uid, _semester).first;
              if (widget.user != null) {
                await PdfService.generateKRS(
                  user: widget.user!,
                  krsList: krsList,
                  semester: _semester,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Semester Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Semester: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _semester,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ['1', '2', '3', '4', '5', '6', '7', '8']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('Semester $s'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
              ],
            ),
          ),

          // KRS List
          Expanded(
            child: StreamBuilder<List<KrsModel>>(
              stream: _fsService.getKrs(uid, _semester),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final krsList = snapshot.data!;
                final totalSks = krsList.fold(0, (s, k) => s + k.sks);

                if (krsList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.list_alt,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'KRS kosong. Tambah mata kuliah!',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Mata Kuliah'),
                          onPressed: () => _showCoursePicker(context, uid),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: AppTheme.success.withOpacity(0.1),
                        child: ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: AppTheme.success,
                          ),
                          title: Text(
                            'Total SKS Semester $_semester',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            '$totalSks SKS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: krsList.length,
                        itemBuilder: (_, i) {
                          final k = krsList[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  k.kode.substring(0, 2),
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                k.namaMatkul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('${k.kode} • ${k.sks} SKS'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: k.status == 'approved'
                                          ? AppTheme.success.withOpacity(0.1)
                                          : AppTheme.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      k.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: k.status == 'approved'
                                            ? AppTheme.success
                                            : AppTheme.warning,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _fsService.deleteKrs(k.id),
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
        onPressed: () => _showCoursePicker(context, uid),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  void _showCoursePicker(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Mata Kuliah',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CourseModel>>(
                stream: _fsService.getCourses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, i) {
                      final c = snapshot.data![i];
                      return ListTile(
                        title: Text(c.nama),
                        subtitle: Text('${c.kode} • ${c.sks} SKS • ${c.dosen}'),
                        trailing: ElevatedButton(
                          child: const Text('Ambil'),
                          onPressed: () async {
                            try {
                              await _fsService.addKrs(
                                KrsModel(
                                  id: '',
                                  uid: uid,
                                  courseId: c.id,
                                  namaMatkul: c.nama,
                                  kode: c.kode,
                                  sks: c.sks,
                                  semester: _semester,
                                  status: 'pending',
                                ),
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
