import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';
import 'package:swear_jar/presentation/utils/environment_util.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        if (errText.contains('Null check operator') ||
            errText.contains('popup-closed') ||
            errText.contains('cancelled-popup')) {
          // Suppress Safari popup closing / internal null artifact
          return;
        }
        setState(() {
          _errorMessage = errText;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocalhost = EnvironmentUtil.isLocalhost;
    // On deployed/non-localhost environments, always enforce Live Mode
    final isLiveMode = !isLocalhost || ref.watch(isLiveModeProvider);
    final firebaseInitError = ref.watch(firebaseInitErrorProvider);
    final users = ref.watch(usersListProvider).valueOrNull ?? [];
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isDesktop = AppBreakpoints.isDesktop(context);

    if (currentUser != null && currentUser.isPending) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: NeonCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentWarning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentWarning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 32,
                        color: AppColors.accentWarning,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Approval Pending',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${currentUser.displayName}! Your account is waiting for approval from the group Admin.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    NeonButton(
                      label: 'Switch Account / Sign Out',
                      type: NeonButtonType.secondary,
                      width: double.infinity,
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (currentUser != null && currentUser.isRejected) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: NeonCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentError.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentError.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        size: 32,
                        color: AppColors.accentError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your account membership request was declined by the group Admin.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    NeonButton(
                      label: 'Sign Out',
                      type: NeonButtonType.secondary,
                      width: double.infinity,
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final brandIdentity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 40,
            color: AppColors.accentPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SWEAR JAR 2.0',
          style: GoogleFonts.outfit(
            fontSize: isDesktop ? 30 : 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Private Group Accountability Ledger',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final errorBanners = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (firebaseInitError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.accentError.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentError.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.accentError, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Firebase Setup Warning',
                      style: GoogleFonts.inter(
                        color: AppColors.accentError,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  firebaseInitError,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.accentError.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentError.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.accentError, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage ?? '',
                    style: GoogleFonts.inter(
                      color: AppColors.accentError,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final authCard = isLiveMode
        ? NeonCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign In',
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your Google account to access your friend group jar.',
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                NeonButton(
                  label: _isLoading ? 'Signing In...' : 'Sign In with Google',
                  icon: _isLoading ? null : Icons.account_circle_outlined,
                  isLoading: _isLoading,
                  width: double.infinity,
                  type: NeonButtonType.primary,
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ),
              ],
            ),
          )
        : NeonCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Local Demo Personas',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const StatusPill(
                      label: 'Mock Mode',
                      color: AppColors.accentInfo,
                      icon: Icons.developer_mode,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a member profile to test the app offline (Localhost only):',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                for (final user in users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(authRepositoryProvider)
                            .signInWithDemo(user.id);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: user.isKeeper
                                ? AppColors.accentPrimary
                                    .withValues(alpha: 0.35)
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
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    user.roles
                                        .map((r) => r.name.toUpperCase())
                                        .join(' • '),
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
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );

    final modeToggleButton = isLocalhost
        ? TextButton.icon(
            onPressed: () {
              ref.read(isLiveModeProvider.notifier).state = !isLiveMode;
            },
            icon: Icon(
              isLiveMode
                  ? Icons.bug_report_outlined
                  : Icons.cloud_done_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
            label: Text(
              isLiveMode
                  ? 'Switch to Local Demo Mode'
                  : 'Switch to Live Firebase Mode',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          )
        : null;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 860 : 440),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              brandIdentity,
                              if (modeToggleButton != null) ...[
                                const SizedBox(height: 24),
                                modeToggleButton,
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            errorBanners,
                            authCard,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      brandIdentity,
                      const SizedBox(height: 32),
                      errorBanners,
                      authCard,
                      if (modeToggleButton != null) ...[
                        const SizedBox(height: 24),
                        modeToggleButton,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

