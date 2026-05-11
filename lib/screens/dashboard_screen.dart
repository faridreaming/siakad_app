import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'krs_screen.dart';
import 'khs_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _fsService = FirestoreService();
  UserModel? _user;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _authService.getUserData(uid);
      if (mounted) setState(() => _user = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(user: _user, fsService: _fsService),
      KrsScreen(user: _user),
      KhsScreen(user: _user),
      ProfileScreen(user: _user),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'KRS',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: 'KHS',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final UserModel? user;
  final FirestoreService fsService;
  const _HomeTab({this.user, required this.fsService});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _selectedSemester = '5'; // semester aktif default

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Card ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang,',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user?.nama ?? '...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _badge(widget.user?.nim ?? '-'),
                        const SizedBox(width: 8),
                        _badge(widget.user?.prodi ?? '-'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pilih Semester Aktif ──────────────────────
              Row(
                children: [
                  const Text(
                    'Semester Aktif:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedSemester,
                    underline: const SizedBox(),
                    items: ['1', '2', '3', '4', '5', '6', '7', '8']
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text('Sem $s')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSemester = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Stat Cards (KRS + IPK) ────────────────────
              StreamBuilder(
                stream: widget.fsService.getKrs(uid, _selectedSemester),
                builder: (context, krsSnap) {
                  return StreamBuilder(
                    stream: widget.fsService.getGrades(uid),
                    builder: (context, gradeSnap) {
                      final krsList = krsSnap.data ?? [];
                      final grades = gradeSnap.data ?? [];
                      final totalSksSemester = krsList.fold(
                        0,
                        (s, k) => s + k.sks,
                      );
                      int totalSksAll = grades.fold(0, (s, g) => s + g.sks);
                      double totalBobot = grades.fold(
                        0.0,
                        (s, g) => s + g.bobotNilai,
                      );
                      double ipk = totalSksAll > 0
                          ? totalBobot / totalSksAll
                          : 0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              _StatCard(
                                'IPK',
                                ipk.toStringAsFixed(2),
                                Icons.star_rounded,
                                AppTheme.warning,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                'SKS Semester',
                                '$totalSksSemester',
                                Icons.book_outlined,
                                AppTheme.primary,
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                'Total Nilai',
                                '${grades.length}',
                                Icons.grade_outlined,
                                AppTheme.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── KRS Semester ini ─────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'KRS Semester $_selectedSemester',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${krsList.length} matkul',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (krsList.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Belum ada KRS semester ini',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...krsList.map(
                              (k) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      k.kode.length >= 2
                                          ? k.kode.substring(0, 2)
                                          : k.kode,
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    k.namaMatkul,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${k.kode} • ${k.sks} SKS',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: _statusChip(k.status),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.success;
        break;
      case 'rejected':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
