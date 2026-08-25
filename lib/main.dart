import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:swear_jar/firebase_options.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/presentation/screens/navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseInitError;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    firebaseInitError = e.toString();
  }
  runApp(
    ProviderScope(
      overrides: [
        if (firebaseInitError != null)
          firebaseInitErrorProvider.overrideWith((ref) => firebaseInitError),
      ],
      child: const SwearJarApp(),
    ),
  );
}

class SwearJarApp extends StatelessWidget {
  const SwearJarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swear Jar 2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const NavigationShell(),
    );
  }
}
