import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/select_major_screen.dart';
import 'screens/splash_screen.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyRsuApp());
}

class MyRsuApp extends StatelessWidget {
  const MyRsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MyRSU',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Routes between Login -> Onboarding (pick major) -> Home, driven by
/// Firebase Auth state plus the student's Firestore profile.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final firebaseUser = authSnap.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return StreamBuilder<AppUser?>(
          stream: FirestoreService.instance.watchUser(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            final user = userSnap.data;
            if (user == null || !user.hasCompletedOnboarding) {
              return const SelectMajorScreen();
            }
            return const HomeShell();
          },
        );
      },
    );
  }
}
