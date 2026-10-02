import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/domain/models/models.dart';
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
    final isDesktop = AppBreakpoints.isDesktop(context);

    final greetingHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${currentUser.displayName}',
              style: GoogleFonts.outfit(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (isKeeper) ...[
                  const Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: AppColors.accentPrimary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  isKeeper ? 'Active Group Keeper' : 'Member',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isKeeper ? AppColors.accentPrimary : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        UserAvatar(user: currentUser, size: 42),
      ],
    );

    final keeperInfoCard = _buildKeeperInfoCard(
      context: context,
      currentUser: currentUser,
      keeper: keeper,
      isKeeper: isKeeper,
    );

    final balanceCard = _buildBalanceCard(
      context: context,
      myTotalDebt: myTotalDebt,
      keeper: keeper,
    );

    final transferredBountyCard = transferredDebts.isNotEmpty
        ? _buildTransferredBountyCard(transferredDebts)
        : null;

    final actionButtons = Row(
      children: [
        Expanded(
          child: NeonButton(
            label: 'Report a Swear',
            icon: Icons.add_circle_outline_rounded,
            type: NeonButtonType.primary,
            onPressed: onNavigateToReport,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeonButton(
            label: 'View Group Jar',
            icon: Icons.account_balance_outlined,
            type: NeonButtonType.secondary,
            onPressed: onNavigateToJar,
          ),
        ),
      ],
    );

    final obligationsSection = _buildObligationsSection(myDebts);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              config?.groupName ?? 'Swear Jar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1120 : 600),
          child: isDesktop
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: greetingHeader),
                        const SizedBox(width: 24),
                        SizedBox(width: 360, child: actionButtons),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              balanceCard,
                              const SizedBox(height: 16),
                              keeperInfoCard,
                              if (transferredBountyCard != null) ...[
                                const SizedBox(height: 16),
                                transferredBountyCard,
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 6,
                          child: obligationsSection,
                        ),
                      ],
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    greetingHeader,
                    const SizedBox(height: 16),
                    keeperInfoCard,
                    const SizedBox(height: 16),
                    balanceCard,
                    if (transferredBountyCard != null) ...[
                      const SizedBox(height: 16),
                      transferredBountyCard,
                    ],
                    const SizedBox(height: 24),
                    actionButtons,
                    const SizedBox(height: 28),
                    obligationsSection,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildKeeperInfoCard({
    required BuildContext context,
    required AppUser currentUser,
    required AppUser? keeper,
    required bool isKeeper,
  }) {
    if (!isKeeper) {
      if (keeper != null &&
          keeper.gcashNumber != null &&
          keeper.gcashNumber!.trim().isNotEmpty) {
        return NeonCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.accentInfo.withValues(alpha: 0.3),
          backgroundColor: AppColors.bgSurface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentInfo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accentInfo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'JAR KEEPER GCASH',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.accentInfo,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '(${keeper.displayName})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      keeper.gcashNumber!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy GCash Number',
                icon: const Icon(Icons.copy_rounded, color: AppColors.accentInfo, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentInfo.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: keeper.gcashNumber!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Copied GCash: ${keeper.gcashNumber} to clipboard!'),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.accentInfo,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      } else if (keeper != null) {
        return NeonCard(
          padding: const EdgeInsets.all(14),
          borderColor: AppColors.borderDefault,
          backgroundColor: AppColors.bgSurface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_android_outlined,
                  color: AppColors.accentWarning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JAR KEEPER: ${keeper.displayName}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keeper has not registered a GCash number yet.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        return NeonCard(
          padding: const EdgeInsets.all(14),
          borderColor: AppColors.borderDefault,
          backgroundColor: AppColors.bgSurface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'No Jar Keeper is currently appointed.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      final hasGcash = currentUser.gcashNumber?.isNotEmpty ?? false;
      return NeonCard(
        padding: const EdgeInsets.all(14),
        borderColor: hasGcash
            ? AppColors.accentPrimary.withValues(alpha: 0.3)
            : AppColors.accentWarning.withValues(alpha: 0.4),
        backgroundColor: AppColors.bgSurface,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasGcash
                    ? AppColors.accentPrimary.withValues(alpha: 0.12)
                    : AppColors.accentWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: hasGcash ? AppColors.accentPrimary : AppColors.accentWarning,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR KEEPER GCASH (Visible to Members)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: hasGcash ? AppColors.accentPrimary : AppColors.accentWarning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasGcash
                        ? currentUser.gcashNumber!
                        : 'Not set yet — please add your GCash in Profile tab.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasGcash ? AppColors.textPrimary : AppColors.accentWarning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBalanceCard({
    required BuildContext context,
    required double myTotalDebt,
    required AppUser? keeper,
  }) {
    return NeonCard(
      hasGlow: myTotalDebt > 0,
      borderColor: myTotalDebt > 0
          ? AppColors.accentPrimary.withValues(alpha: 0.4)
          : AppColors.borderDefault,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'YOUR JAR BALANCE',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (myTotalDebt > 0)
                const StatusPill(
                  label: 'Obligation Active',
                  color: AppColors.accentWarning,
                  icon: Icons.pending_outlined,
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
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: myTotalDebt > 0 ? Colors.white : AppColors.accentSuccess,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderDefault, height: 1),
          const SizedBox(height: 12),
          if (myTotalDebt > 0 && keeper != null) ...[
            Row(
              children: [
                const Icon(Icons.arrow_outward, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'Payable to: '),
                        TextSpan(
                          text: keeper.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const TextSpan(text: ' (Keeper)'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (keeper.gcashNumber != null && keeper.gcashNumber!.isNotEmpty) ...[
              const SizedBox(height: 10),
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
                      const Icon(Icons.phone_android_outlined, size: 14, color: AppColors.accentInfo),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'GCash: ${keeper.gcashNumber}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentInfo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppColors.accentSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You do not owe any money right now.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.accentSuccess),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferredBountyCard(List<DebtObligation> transferredDebts) {
    return NeonCard(
      backgroundColor: AppColors.accentPrimary.withValues(alpha: 0.08),
      borderColor: AppColors.accentPrimary.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(16),
      onTap: onNavigateToJar,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: AppColors.accentPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keeper Swear Bounty Active',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You hold ${transferredDebts.length} transferred balance(s) worth ₱${transferredDebts.fold<double>(0.0, (s, d) => s + d.remainingBalance).toStringAsFixed(0)}.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildObligationsSection(List<DebtObligation> myDebts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR ACTIVE OBLIGATIONS',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        if (myDebts.isEmpty)
          NeonCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSuccess.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 28, color: AppColors.accentSuccess),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Clean Record',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No pending debts or swear obligations.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          for (final debt in myDebts)
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
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: AppColors.accentWarning, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.isTransferred ? 'Transferred Penalty' : 'Swear Penalty',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 4),
                        StatusPill.fromDebt(debt.status, isTransferred: debt.isTransferred),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

