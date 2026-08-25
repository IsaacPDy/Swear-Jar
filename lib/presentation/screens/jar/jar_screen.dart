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
    final isKeeperOrAdmin = (currentUser?.isKeeper ?? false) || (currentUser?.isAdmin ?? false);

    AppUser getUser(String uid) {
      return users.firstWhere(
        (u) => u.id == uid,
        orElse: () => AppUser(
          id: uid,
          email: '',
          displayName: 'Member ($uid)',
          roles: const [UserRole.member],
          status: UserStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final transferredDebts = activeDebts.where((d) => d.isTransferred).toList();
    final standardDebts = activeDebts.where((d) => !d.isTransferred).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Group Jar & Ledger', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              NeonCard(
                hasGlow: groupTotalDebt > 0,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL GROUP OUTSTANDING',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CurrencyText(
                      amount: groupTotalDebt,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: groupTotalDebt > 0 ? AppColors.accentPrimary : AppColors.accentSuccess,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All-Time Swears', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  '${config?.totalSwearsAllTime ?? 0}',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active Keeper', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  keeper?.displayName.split(' ').first ?? 'None',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentPrimary),
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
              ),
              if (transferredDebts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.accentPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'TRANSFERRED BALANCES (KEEPER BOUNTIES)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final debt in transferredDebts) ...[
                  _buildDebtCard(
                    context: context,
                    ref: ref,
                    debt: debt,
                    debtor: getUser(debt.debtorId),
                    recipient: getUser(debt.recipientId),
                    currentUser: currentUser,
                    isTransferred: true,
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Text(
                'ACTIVE OBLIGATIONS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              if (standardDebts.isEmpty)
                NeonCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No active standard debts. The jar is balanced!',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                for (final debt in standardDebts) ...[
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
            ],
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
        padding: const EdgeInsets.all(16),
        borderColor: isTransferred ? AppColors.accentPrimary.withValues(alpha: 0.4) : AppColors.borderDefault,
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(user: debtor, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debtor.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Owed to: ${recipient.displayName}${isTransferred ? " (Bounty Holder)" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isTransferred ? AppColors.accentPrimary : AppColors.textSecondary,
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
                      fontWeight: FontWeight.bold,
                    ),
                    StatusPill.fromDebt(debt.status, isTransferred: isTransferred),
                  ],
                ),
              ],
            ),
            if (debt.payments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Paid: ₱${(debt.originalAmount - debt.remainingBalance).toStringAsFixed(0)} / ₱${debt.originalAmount.toStringAsFixed(0)} (${debt.payments.length} payment records)',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canManagePayment) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isTransferred) ...[
                    Expanded(
                      child: NeonButton(
                        label: 'Dismiss Debt',
                        type: NeonButtonType.danger,
                        icon: Icons.delete_outline,
                        onPressed: () => _showDismissDialog(context, ref, debt, currentUser!),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: NeonButton(
                      label: 'Record Payment',
                      type: NeonButtonType.mint,
                      icon: Icons.payments_outlined,
                      onPressed: () => _showRecordPaymentModal(context, ref, debt, debtor, currentUser!),
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
    final amountController = TextEditingController(text: debt.remainingBalance.toStringAsFixed(0));
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Payment for ${debtor.displayName}',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Outstanding Balance: ₱${debt.remainingBalance.toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Payment Amount (₱)',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional, e.g. GCash ref #)',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'Confirm Payment',
              icon: Icons.check,
              type: NeonButtonType.mint,
              width: double.infinity,
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim());
                if (amt == null || amt <= 0) return;

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                await ref.read(ledgerRepositoryProvider).recordPayment(
                      debt: debt,
                      amount: amt,
                      recordedBy: currentUser.id,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Recorded ₱${amt.toStringAsFixed(0)} payment for ${debtor.displayName}!'),
                    backgroundColor: AppColors.accentSuccess,
                  ),
                );
              },
            ),
          ],
        ),
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
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Dismiss Transferred Debt?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'As the recipient of this Keeper bounty, you have authority to forgive the remaining ₱${debt.remainingBalance.toStringAsFixed(0)} balance.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
