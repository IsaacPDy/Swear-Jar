import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

    if (currentUser == null || currentUser.isPending || currentUser.isRejected) {
      return const AuthScreen();
    }

    final pendingReports = ref.watch(pendingReportsProvider);
    final isDesktop = AppBreakpoints.isDesktop(context);

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

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                border: Border(
                  right: BorderSide(color: AppColors.borderDefault, width: 1),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.accentPrimary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.accentPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SWEAR JAR',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderDefault),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          _buildDesktopNavItem(
                            index: 0,
                            label: 'Home',
                            icon: Icons.dashboard_outlined,
                            activeIcon: Icons.dashboard_rounded,
                          ),
                          const SizedBox(height: 4),
                          _buildDesktopNavItem(
                            index: 1,
                            label: 'Reports',
                            icon: Icons.receipt_long_outlined,
                            activeIcon: Icons.receipt_long_rounded,
                            badgeCount: pendingReports.length,
                          ),
                          const SizedBox(height: 4),
                          _buildDesktopNavItem(
                            index: 2,
                            label: 'Report',
                            icon: Icons.add_circle_outline_rounded,
                            activeIcon: Icons.add_circle_rounded,
                            isPrimaryAction: true,
                          ),
                          const SizedBox(height: 4),
                          _buildDesktopNavItem(
                            index: 3,
                            label: 'Jar',
                            icon: Icons.account_balance_outlined,
                            activeIcon: Icons.account_balance_rounded,
                          ),
                          const SizedBox(height: 4),
                          _buildDesktopNavItem(
                            index: 4,
                            label: 'Profile',
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded, color: AppColors.accentPrimary),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: pendingReports.isNotEmpty,
                label: Text('${pendingReports.length}'),
                backgroundColor: AppColors.accentWarning,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: pendingReports.isNotEmpty,
                label: Text('${pendingReports.length}'),
                backgroundColor: AppColors.accentWarning,
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.accentPrimary),
              ),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: AppColors.accentPrimary, size: 20),
              ),
              label: 'Report',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance_rounded, color: AppColors.accentPrimary),
              label: 'Jar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppColors.accentPrimary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
    bool isPrimaryAction = false,
  }) {
    final isSelected = _currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentPrimary.withValues(alpha: 0.14)
                : (isPrimaryAction
                    ? AppColors.bgSurfaceElevated.withValues(alpha: 0.6)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPrimary.withValues(alpha: 0.35)
                  : (isPrimaryAction ? AppColors.borderDefault : Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 19,
                color: isSelected
                    ? AppColors.accentPrimary
                    : (isPrimaryAction ? AppColors.textPrimary : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentWarning.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentWarning,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

