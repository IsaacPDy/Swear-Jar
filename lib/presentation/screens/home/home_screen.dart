import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToReport;
  final VoidCallback? onNavigateToJar;

  const HomeScreen({
    super.key,
    this.onNavigateToReport,
    this.onNavigateToJar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final keeper = ref.watch(activeKeeperProvider);
    final myTotalDebt = ref.watch(myTotalDebtAmountProvider);
    final myDebts = ref.watch(myDebtsProvider);
    final transferredDebts = ref.watch(transferredDebtsOwedToMeProvider);
    final config = ref.watch(systemConfigProvider).valueOrNull;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isKeeper = currentUser.id == keeper?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.savings_rounded, color: AppColors.accentPrimary, size: 24),
            const SizedBox(width: 8),
            Text(config?.groupName ?? 'Swear Jar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${currentUser.displayName} 👋',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isKeeper ? '👑 Active Group Keeper' : 'Member',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isKeeper ? AppColors.accentPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  UserAvatar(user: currentUser, size: 42),
                ],
              ),
              const SizedBox(height: 16),
              NeonCard(
                hasGlow: myTotalDebt > 0,
                borderColor: myTotalDebt > 0 ? AppColors.accentPrimary.withValues(alpha: 0.5) : AppColors.borderDefault,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR JAR BALANCE',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (myTotalDebt > 0)
                          const StatusPill(
                            label: 'Obligation Active',
                            color: AppColors.accentWarning,
                            icon: Icons.pending,
                          )
                        else
                          const StatusPill(
                            label: 'All Settled',
                            color: AppColors.accentSuccess,
                            icon: Icons.check_circle_outline,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CurrencyText(
                      amount: myTotalDebt,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: myTotalDebt > 0 ? Colors.white : AppColors.accentSuccess,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderDefault),
                    const SizedBox(height: 8),
                    if (myTotalDebt > 0 && keeper != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.arrow_outward, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                children: [
                                  const TextSpan(text: 'Payable to: '),
                                  TextSpan(
                                    text: keeper.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const TextSpan(text: ' (Keeper)'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (keeper.gcashNumber != null && keeper.gcashNumber!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: keeper.gcashNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied GCash: ${keeper.gcashNumber} to clipboard!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.accentPrimary,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accentInfo.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_android, size: 14, color: AppColors.accentInfo),
                                const SizedBox(width: 6),
                                Text(
                                  'GCash: ${keeper.gcashNumber}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentInfo,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy, size: 12, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      const Row(
                        children: [
                          Icon(Icons.sentiment_satisfied_alt, size: 18, color: AppColors.accentSuccess),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You do not owe any money right now! Keep it clean! 🎉',
                              style: TextStyle(fontSize: 13, color: AppColors.accentSuccess),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (transferredDebts.isNotEmpty) ...[
                const SizedBox(height: 16),
                NeonCard(
                  backgroundColor: AppColors.accentPrimary.withValues(alpha: 0.1),
                  borderColor: AppColors.accentPrimary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(16),
                  onTap: onNavigateToJar,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt, color: AppColors.accentPrimary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keeper Swear Bounty Active!',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'You hold ${transferredDebts.length} transferred balance(s) worth ₱${transferredDebts.fold<double>(0.0, (s, d) => s + d.remainingBalance).toStringAsFixed(0)}.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: 'Report a Swear',
                      icon: Icons.add_circle_outline,
                      type: NeonButtonType.primary,
                      onPressed: onNavigateToReport,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      label: 'View Group Jar',
                      icon: Icons.pie_chart_outline,
                      type: NeonButtonType.secondary,
                      onPressed: onNavigateToJar,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'YOUR ACTIVE OBLIGATIONS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (myDebts.isEmpty)
                NeonCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 36, color: AppColors.accentSuccess),
                        const SizedBox(height: 8),
                        Text(
                          'Clean Record',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Text(
                          'No pending debts or swear obligations.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final debt in myDebts) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: NeonCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long, color: AppColors.accentWarning, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  debt.isTransferred ? 'Transferred Penalty' : 'Swear Penalty',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                                ),
                                Text(
                                  'Original: ₱${debt.originalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CurrencyText(
                                amount: debt.remainingBalance,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              StatusPill.fromDebt(debt.status, isTransferred: debt.isTransferred),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
