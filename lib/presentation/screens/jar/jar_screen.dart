import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class JarScreen extends ConsumerWidget {
  const JarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupTotalDebt = ref.watch(groupTotalActiveDebtProvider);
    final activeDebts = ref.watch(activeDebtsProvider);
    final config = ref.watch(systemConfigProvider).valueOrNull;
    final users = ref.watch(usersListProvider).valueOrNull ?? [];
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final keeper = ref.watch(activeKeeperProvider);
    final isKeeperOrAdmin =
        (currentUser?.isKeeper ?? false) || (currentUser?.isAdmin ?? false);
    final isDesktop = AppBreakpoints.isDesktop(context);

    AppUser getUser(String uid) {
      return users.firstWhere(
        (u) => u.id == uid,
        orElse: () => AppUser(
          id: uid,
          email: '',
          displayName: 'Former Member',
          roles: const [UserRole.member],
          status: UserStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final transferredDebts = activeDebts.where((d) => d.isTransferred).toList();
    final standardDebts = activeDebts.where((d) => !d.isTransferred).toList();

    final pageHeader = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEDGER',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.accentGoldMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Group Jar & Ledger',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 30 : 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Overview of active group obligations, payments, and transferred Keeper bounties.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final summaryCard = NeonCard(
      hasGlow: groupTotalDebt > 0,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL GROUP OUTSTANDING',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          CurrencyText(
            amount: groupTotalDebt,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: groupTotalDebt > 0
                ? AppColors.textPrimary
                : AppColors.accentMint,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All-Time Swears',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${config?.totalSwearsAllTime ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentMint,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Keeper',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keeper?.displayName.split(' ').first ?? 'None',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final debtsLedgerColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transferredDebts.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.accentPrimary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TRANSFERRED BALANCES (KEEPER BOUNTIES)',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final debt in transferredDebts)
            _buildDebtCard(
              context: context,
              ref: ref,
              debt: debt,
              debtor: getUser(debt.debtorId),
              recipient: getUser(debt.recipientId),
              currentUser: currentUser,
              isTransferred: true,
            ),
          const SizedBox(height: 16),
        ],
        Text(
          'ACTIVE OBLIGATIONS',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (standardDebts.isEmpty)
          NeonCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: Text(
                'No active standard debts. The jar is balanced!',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          for (final debt in standardDebts)
            _buildDebtCard(
              context: context,
              ref: ref,
              debt: debt,
              debtor: getUser(debt.debtorId),
              recipient: getUser(debt.recipientId),
              currentUser: currentUser,
              isTransferred: false,
              isKeeperOrAdmin: isKeeperOrAdmin,
            ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1140 : 600),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: isDesktop ? 28 : 16,
              ),
              children: [
                pageHeader,
                const SizedBox(height: 22),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: summaryCard),
                      const SizedBox(width: 24),
                      Expanded(flex: 7, child: debtsLedgerColumn),
                    ],
                  )
                else ...[
                  summaryCard,
                  const SizedBox(height: 24),
                  debtsLedgerColumn,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard({
    required BuildContext context,
    required WidgetRef ref,
    required DebtObligation debt,
    required AppUser debtor,
    required AppUser recipient,
    required AppUser? currentUser,
    required bool isTransferred,
    bool isKeeperOrAdmin = false,
  }) {
    final canManagePayment = isTransferred
        ? (currentUser?.id == recipient.id)
        : (isKeeperOrAdmin || currentUser?.id == recipient.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeonCard(
        padding: const EdgeInsets.all(18),
        borderColor: isTransferred
            ? AppColors.accentPrimary.withValues(alpha: 0.35)
            : AppColors.borderDefault,
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(user: debtor, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debtor.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Owed to: ${recipient.displayName}${isTransferred ? " (Bounty Holder)" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: isTransferred
                              ? AppColors.accentPrimary
                              : AppColors.textSecondary,
                        ),
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
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 4),
                    StatusPill.fromDebt(
                      debt.status,
                      isTransferred: isTransferred,
                    ),
                  ],
                ),
              ],
            ),
            if (debt.payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 14,
                      color: AppColors.accentMint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paid: ₱${(debt.originalAmount - debt.remainingBalance).toStringAsFixed(0)} / ₱${debt.originalAmount.toStringAsFixed(0)} (${debt.payments.length} payment records)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canManagePayment) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (isTransferred) ...[
                    Expanded(
                      child: NeonButton(
                        label: 'Dismiss Debt',
                        type: NeonButtonType.danger,
                        icon: Icons.delete_outline,
                        onPressed: () => _showDismissDialog(
                          context,
                          ref,
                          debt,
                          currentUser!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: NeonButton(
                      label: 'Record Payment',
                      type: NeonButtonType.mint,
                      icon: Icons.payments_outlined,
                      onPressed: () => _showRecordPaymentModal(
                        context,
                        ref,
                        debt,
                        debtor,
                        currentUser!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentModal(
    BuildContext context,
    WidgetRef ref,
    DebtObligation debt,
    AppUser debtor,
    AppUser currentUser,
  ) {
    final amountController =
        TextEditingController(text: debt.remainingBalance.toStringAsFixed(0));
    final noteController = TextEditingController();
    final isDesktop = AppBreakpoints.isDesktop(context);

    Widget buildForm(BuildContext modalCtx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Payment for ${debtor.displayName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Outstanding Balance: ₱${debt.remainingBalance.toStringAsFixed(0)}',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Payment Amount (₱)',
              labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.bgSurfaceElevated,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderDefault),
              ),
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: 'Note (Optional, e.g. GCash ref #)',
              labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.bgSurfaceElevated,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderDefault),
              ),
            ),
            style:
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          NeonButton(
            label: 'Confirm Payment',
            icon: Icons.check_rounded,
            type: NeonButtonType.mint,
            width: double.infinity,
            onPressed: () async {
              final amt = double.tryParse(amountController.text.trim());
              if (amt == null || amt <= 0) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(modalCtx);
              await ref.read(ledgerRepositoryProvider).recordPayment(
                    debt: debt,
                    amount: amt,
                    recordedBy: currentUser.id,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Recorded ₱${amt.toStringAsFixed(0)} payment for ${debtor.displayName}!',
                  ),
                  backgroundColor: AppColors.accentSuccess,
                ),
              );
            },
          ),
        ],
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderDefault),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: buildForm(ctx),
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: AppColors.borderDefault),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: buildForm(ctx),
      ),
    );
  }

  void _showDismissDialog(
    BuildContext context,
    WidgetRef ref,
    DebtObligation debt,
    AppUser currentUser,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Dismiss Transferred Debt?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            'As the recipient of this Keeper bounty, you have authority to forgive the remaining ₱${debt.remainingBalance.toStringAsFixed(0)} balance.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          NeonButton(
            label: 'Forgive / Dismiss',
            type: NeonButtonType.danger,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(ledgerRepositoryProvider).dismissTransferredDebt(
                    debt: debt,
                    dismissedBy: currentUser.id,
                    reason: 'Forgiven by bounty recipient',
                  );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Transferred debt dismissed.'),
                  backgroundColor: AppColors.textMuted,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
