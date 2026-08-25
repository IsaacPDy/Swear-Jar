import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/presentation/screens/home/home_screen.dart';
import 'package:swear_jar/presentation/screens/reports/reports_screen.dart';
import 'package:swear_jar/presentation/screens/report_swear/report_swear_screen.dart';
import 'package:swear_jar/presentation/screens/jar/jar_screen.dart';
import 'package:swear_jar/presentation/screens/profile/profile_screen.dart';
import 'package:swear_jar/presentation/screens/auth/auth_screen.dart';

class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser == null || currentUser.isPending) {
      return const AuthScreen();
    }

    final pendingReports = ref.watch(pendingReportsProvider);

    final screens = [
      HomeScreen(
        onNavigateToReport: () => _onTabSelected(2),
        onNavigateToJar: () => _onTabSelected(3),
      ),
      const ReportsScreen(),
      ReportSwearScreen(
        onReportSubmitted: () => _onTabSelected(1),
      ),
      const JarScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(top: BorderSide(color: AppColors.borderDefault, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: AppColors.accentPrimary),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: pendingReports.isNotEmpty,
                label: Text('${pendingReports.length}'),
                backgroundColor: AppColors.accentWarning,
                child: const Icon(Icons.description_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: pendingReports.isNotEmpty,
                label: Text('${pendingReports.length}'),
                backgroundColor: AppColors.accentWarning,
                child: const Icon(Icons.description, color: AppColors.accentPrimary),
              ),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGlow,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: AppColors.accentPrimary, size: 22),
              ),
              label: 'Report',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart, color: AppColors.accentPrimary),
              label: 'Jar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.accentPrimary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
