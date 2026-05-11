import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'admin_courses_screen.dart';
import 'admin_mahasiswa_screen.dart';
import 'admin_krs_screen.dart';
import 'admin_grades_screen.dart';
import 'admin_monitoring_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final _pages = const [
    AdminMonitoringScreen(),
    AdminCoursesScreen(),
    AdminKrsScreen(),
    AdminGradesScreen(),
    AdminMahasiswaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Matkul',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'KRS',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: 'Nilai',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Mahasiswa',
          ),
        ],
      ),
    );
  }
}
