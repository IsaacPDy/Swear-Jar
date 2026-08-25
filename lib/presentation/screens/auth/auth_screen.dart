import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersListProvider).valueOrNull ?? [];
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser != null && currentUser.isPending) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: NeonCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentWarning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top,
                        size: 40,
                        color: AppColors.accentWarning,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Approval Pending',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${currentUser.displayName}! Your account is waiting for approval from the group Admin.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    NeonButton(
                      label: 'Switch Account / Sign Out',
                      type: NeonButtonType.secondary,
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.accentGlow,
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    size: 52,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SWEAR JAR 2.0',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Private Group Accountability Ledger',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
                NeonCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Demo Quick Sign-In',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a member profile to test the app locally:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final user in users) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () {
                              ref.read(authRepositoryProvider).signInWithDemo(user.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: user.isKeeper
                                      ? AppColors.accentPrimary.withValues(alpha: 0.4)
                                      : AppColors.borderDefault,
                                ),
                              ),
                              child: Row(
                                children: [
                                  UserAvatar(user: user, size: 36),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          user.roles.map((r) => r.name.toUpperCase()).join(' • '),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: user.isKeeper
                                                ? AppColors.accentPrimary
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (user.isPending)
                                    const StatusPill(
                                      label: 'Pending',
                                      color: AppColors.accentWarning,
                                      icon: Icons.hourglass_empty,
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.borderDefault),
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'Sign In with Google',
                        icon: Icons.login,
                        width: double.infinity,
                        type: NeonButtonType.primary,
                        onPressed: () {
                          ref.read(authRepositoryProvider).signInWithGoogle();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
