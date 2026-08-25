import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/screens/navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SwearJarApp(),
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
