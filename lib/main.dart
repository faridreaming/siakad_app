import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SiakadApp());
}

class SiakadApp extends StatelessWidget {
  const SiakadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAKAD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // Cek role setelah login
            return FutureBuilder<String>(
              future: AuthService().getCurrentRole(),
              builder: (context, roleSnap) {
                if (!roleSnap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (roleSnap.data == 'admin') {
                  return const AdminShell();
                }
                return const DashboardScreen();
              },
            );
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
