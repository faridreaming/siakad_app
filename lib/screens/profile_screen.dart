import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primary,
              child: Text(
                user?.nama.isNotEmpty == true
                    ? user!.nama[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nama ?? '-',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? '-',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(Icons.badge_outlined, 'NIM', user?.nim ?? '-'),
                    const Divider(),
                    _infoRow(
                      Icons.school_outlined,
                      'Program Studi',
                      user?.prodi ?? '-',
                    ),
                    const Divider(),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Angkatan',
                      user?.angkatan ?? '-',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              onPressed: () => AuthService().logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
