import 'package:flutter/material.dart';
import '../../models/krs_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminKrsScreen extends StatefulWidget {
  const AdminKrsScreen({super.key});

  @override
  State<AdminKrsScreen> createState() => _AdminKrsScreenState();
}

class _AdminKrsScreenState extends State<AdminKrsScreen> {
  final _fs = FirestoreService();
  String _filterStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✅ Approval KRS')),
      body: Column(
        children: [
          // Tab filter status
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pending',
                  label: Text('Pending'),
                  icon: Icon(Icons.pending_actions, size: 16),
                ),
                ButtonSegment(
                  value: 'approved',
                  label: Text('Disetujui'),
                  icon: Icon(Icons.check_circle, size: 16),
                ),
                ButtonSegment(
                  value: 'rejected',
                  label: Text('Ditolak'),
                  icon: Icon(Icons.cancel, size: 16),
                ),
              ],
              selected: {_filterStatus},
              onSelectionChanged: (s) =>
                  setState(() => _filterStatus = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<KrsModel>>(
              stream: _fs.getAllKrs(status: _filterStatus),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final krsList = snap.data!;
                if (krsList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada KRS dengan status "$_filterStatus"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: krsList.length,
                  itemBuilder: (_, i) {
                    final k = krsList[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    k.namaMatkul,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                _StatusBadge(k.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${k.kode} • ${k.sks} SKS • Semester ${k.semester}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'UID Mahasiswa: ${k.uid}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            if (_filterStatus == 'pending') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.error,
                                        side: const BorderSide(
                                          color: AppTheme.error,
                                        ),
                                      ),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Tolak'),
                                      onPressed: () =>
                                          _fs.updateKrsStatus(k.id, 'rejected'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                      ),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Setujui'),
                                      onPressed: () =>
                                          _fs.updateKrsStatus(k.id, 'approved'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'approved':
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppTheme.error;
        icon = Icons.cancel;
        break;
      default:
        color = AppTheme.warning;
        icon = Icons.pending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
