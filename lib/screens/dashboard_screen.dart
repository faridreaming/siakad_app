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
      setState(() => _user = user);
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
      body: pages[_selectedIndex],
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

class _HomeTab extends StatelessWidget {
  final UserModel? user;
  final FirestoreService fsService;
  const _HomeTab({this.user, required this.fsService});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            // Welcome Card
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
                  Text(
                    'Selamat datang,',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    user?.nama ?? '...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NIM: ${user?.nim ?? '-'}  |  ${user?.prodi ?? '-'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ringkasan Nilai
            Text(
              'Ringkasan Akademik',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: fsService.getGrades(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final grades = snapshot.data!;
                int totalSks = grades.fold(0, (s, g) => s + g.sks);
                double totalBobot = grades.fold(
                  0.0,
                  (s, g) => s + g.bobotNilai,
                );
                double ipk = totalSks > 0 ? totalBobot / totalSks : 0;

                return Row(
                  children: [
                    _StatCard(
                      'IPK',
                      ipk.toStringAsFixed(2),
                      Icons.star,
                      AppTheme.warning,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      'Mata Kuliah',
                      '${grades.length}',
                      Icons.book,
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      'Total SKS',
                      '$totalSks',
                      Icons.credit_score,
                      AppTheme.success,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Seed Button (untuk demo)
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Seed Data Mata Kuliah'),
              onPressed: () async {
                await fsService.seedCourses();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data mata kuliah berhasil ditambahkan!'),
                    ),
                  );
                }
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
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
