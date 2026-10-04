import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class JarScreen extends ConsumerWidget {
  const JarScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupTotalToBeReceived = ref.watch(groupTotalActiveDebtProvider);
    final activeMemberBalances = ref.watch(activeMemberBalancesProvider);
    final paymentHistory = ref.watch(paymentHistoryProvider);
    final allTimeSwears = ref.watch(allTimeSwearsCountProvider);
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

    bool canManageSummary(MemberLedgerSummary summary) {
      if (currentUser == null) return false;
      if (summary.isTransferred) {
        return currentUser.id == summary.recipientId;
      }
      return isKeeperOrAdmin || currentUser.id == summary.recipientId;
    }

    final manageableSummaries =
        activeMemberBalances.where(canManageSummary).toList();
    final transferredBalances =
        activeMemberBalances.where((s) => s.isTransferred).toList();

    // Build per-person "To Be Received" entries for EVERY approved member in the group
    final approvedUsers = users.where((u) => u.isApproved).toList();
    final memberBoxItems = approvedUsers.map((user) {
      final userSummaries = activeMemberBalances
          .where((s) => s.debtorId == user.id && !s.isTransferred)
          .toList();
      final totalToBeReceived = userSummaries.fold<double>(
        0.0,
        (sum, s) => sum + s.toBeReceived,
      );
      final primarySummary = userSummaries.firstOrNull;
      return (
        user: user,
        toBeReceived: totalToBeReceived,
        summary: primarySummary,
      );
    }).toList()
      ..sort((a, b) {
        final cmp = b.toBeReceived.compareTo(a.toBeReceived);
        if (cmp.abs() > 0.001) return cmp;
        return a.user.displayName.compareTo(b.user.displayName);
      });

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
          'Track group balances to be received and payment history.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final summaryCard = NeonCard(
      hasGlow: groupTotalToBeReceived > 0,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TO BE RECEIVED',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          CurrencyText(
            amount: groupTotalToBeReceived,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: groupTotalToBeReceived > 0
                ? AppColors.accentPrimary
                : AppColors.accentMint,
          ),
          const SizedBox(height: 16),
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
                        '$allTimeSwears',
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

    final allDebts = ref.watch(validDebtsProvider);
    final paymentHistorySection = _buildPaymentHistorySection(
      context: context,
      ref: ref,
      paymentHistory: paymentHistory,
      allDebts: allDebts,
      getUser: getUser,
      currentUser: currentUser,
      isKeeperOrAdmin: isKeeperOrAdmin,
    );

    final personCardsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transferredBalances.isNotEmpty) ...[
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
                  'MEMBER RECEIVABLES & BOUNTIES',
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
          for (final summary in transferredBalances)
            _buildTransferredBalanceCard(
              context: context,
              ref: ref,
              summary: summary,
              debtor: getUser(summary.debtorId),
              recipient: getUser(summary.recipientId),
              getUser: getUser,
              currentUser: currentUser,
              canManagePayment: canManageSummary(summary),
              manageableSummaries: manageableSummaries,
            ),
          const SizedBox(height: 16),
        ],
        NeonCard(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          borderRadius: 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 460 ? 3 : 2;
              const spacing = 12.0;
              final tileWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                children: [
                  for (final item in memberBoxItems)
                    SizedBox(
                      width: tileWidth.clamp(110.0, 260.0),
                      child: _buildPersonToBeReceivedCardWithAction(
                        context: context,
                        ref: ref,
                        user: item.user,
                        toBeReceived: item.toBeReceived,
                        summary: item.summary,
                        canManage: item.summary != null &&
                            canManageSummary(item.summary!),
                        manageableSummaries: manageableSummaries,
                        getUser: getUser,
                        currentUser: currentUser,
                      ),
                    ),
                ],
              );
            },
          ),
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
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            summaryCard,
                            const SizedBox(height: 22),
                            paymentHistorySection,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 6,
                        child: personCardsSection,
                      ),
                    ],
                  )
                else ...[
                  summaryCard,
                  const SizedBox(height: 22),
                  paymentHistorySection,
                  const SizedBox(height: 24),
                  personCardsSection,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Person box styled like the "Who swore?" boxes in ReportSwearScreen,
  /// with the "Record Payment" button placed directly below each person card.
  Widget _buildPersonToBeReceivedCardWithAction({
    required BuildContext context,
    required WidgetRef ref,
    required AppUser user,
    required double toBeReceived,
    required MemberLedgerSummary? summary,
    required bool canManage,
    required List<MemberLedgerSummary> manageableSummaries,
    required AppUser Function(String) getUser,
    required AppUser? currentUser,
  }) {
    final hasDebt = toBeReceived > 0.001;
    final canTapToPay =
        hasDebt && canManage && summary != null && currentUser != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canTapToPay
                ? () => _showRecordPaymentModal(
                      context: context,
                      ref: ref,
                      initialSummary: summary,
                      selectableSummaries: manageableSummaries,
                      getUser: getUser,
                      currentUser: currentUser,
                    )
                : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: hasDebt
                    ? const Color(0xFF17202A)
                    : AppColors.bgSurfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDebt
                      ? AppColors.accentPrimary.withValues(alpha: 0.5)
                      : AppColors.borderDefault,
                  width: hasDebt ? 1.4 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(user: user, size: 46, showBadge: false),
                  const SizedBox(height: 10),
                  Text(
                    user.displayName.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'To Be Received',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CurrencyText(
                    amount: toBeReceived,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: hasDebt
                        ? AppColors.accentPrimary
                        : AppColors.accentMint,
                  ),
                  const SizedBox(height: 8),
                  if (hasDebt)
                    StatusPill.fromDebt(DebtStatus.active)
                  else
                    StatusPill.fromDebt(DebtStatus.paid),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        NeonButton(
          label: 'Record Payment',
          icon: Icons.payments_outlined,
          type: canTapToPay ? NeonButtonType.mint : NeonButtonType.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          onPressed: canTapToPay
              ? () => _showRecordPaymentModal(
                    context: context,
                    ref: ref,
                    initialSummary: summary,
                    selectableSummaries: manageableSummaries,
                    getUser: getUser,
                    currentUser: currentUser,
                  )
              : null,
        ),
      ],
    );
  }

  Widget _buildTransferredBalanceCard({
    required BuildContext context,
    required WidgetRef ref,
    required MemberLedgerSummary summary,
    required AppUser debtor,
    required AppUser recipient,
    required AppUser Function(String) getUser,
    required AppUser? currentUser,
    required bool canManagePayment,
    required List<MemberLedgerSummary> manageableSummaries,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeonCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppColors.accentPrimary.withValues(alpha: 0.35),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Payable to: ${recipient.displayName} (Bounty Holder)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CurrencyText(
                      amount: summary.toBeReceived,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 4),
                    StatusPill.fromDebt(
                      DebtStatus.active,
                      isTransferred: true,
                    ),
                  ],
                ),
              ],
            ),
            if (canManagePayment && currentUser != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: 'Dismiss Balance',
                      type: NeonButtonType.danger,
                      icon: Icons.delete_outline,
                      onPressed: () => _showDismissDialog(
                        context,
                        ref,
                        summary,
                        debtor,
                        currentUser,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeonButton(
                      label: 'Record Payment',
                      type: NeonButtonType.mint,
                      icon: Icons.payments_outlined,
                      onPressed: () => _showRecordPaymentModal(
                        context: context,
                        ref: ref,
                        initialSummary: summary,
                        selectableSummaries: manageableSummaries,
                        getUser: getUser,
                        currentUser: currentUser,
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

  /// Payment History section placed below the To Be Received section,
  /// displaying ONLY the history of payments made.
  Widget _buildPaymentHistorySection({
    required BuildContext context,
    required WidgetRef ref,
    required List<PaymentHistoryItem> paymentHistory,
    required List<DebtObligation> allDebts,
    required AppUser Function(String) getUser,
    required AppUser? currentUser,
    required bool isKeeperOrAdmin,
  }) {
    bool canEditPayment(PaymentHistoryItem item) {
      if (currentUser == null) return false;
      return isKeeperOrAdmin || currentUser.id == item.recipientId;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYMENT HISTORY',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Text(
                '${paymentHistory.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (paymentHistory.isEmpty)
          NeonCard(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Center(
              child: Text(
                'No payments recorded yet.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          NeonCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < paymentHistory.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: AppColors.borderDefault,
                        height: 1,
                      ),
                    ),
                  _buildPaymentHistoryRow(
                    context: context,
                    ref: ref,
                    item: paymentHistory[i],
                    debtor: getUser(paymentHistory[i].debtorId),
                    allDebts: allDebts,
                    currentUser: currentUser,
                    canEdit: canEditPayment(paymentHistory[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentHistoryRow({
    required BuildContext context,
    required WidgetRef ref,
    required PaymentHistoryItem item,
    required AppUser debtor,
    required List<DebtObligation> allDebts,
    required AppUser? currentUser,
    required bool canEdit,
  }) {
    final dateText = DateFormat('MMM d, yyyy').format(item.recordedAt);
    final subtitle = (item.note != null && item.note!.trim().isNotEmpty)
        ? '$dateText • ${item.note!.trim()}'
        : dateText;

    return Row(
      children: [
        UserAvatar(user: debtor, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debtor.displayName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '+₱${item.amount.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.accentMint,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (canEdit && currentUser != null) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Edit Payment',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showEditPaymentHistoryModal(
              context: context,
              ref: ref,
              item: item,
              debtor: debtor,
              allDebts: allDebts,
              currentUser: currentUser,
            ),
          ),
        ],
      ],
    );
  }

  void _showEditPaymentHistoryModal({
    required BuildContext context,
    required WidgetRef ref,
    required PaymentHistoryItem item,
    required AppUser debtor,
    required List<DebtObligation> allDebts,
    required AppUser currentUser,
  }) {
    final paymentIdSet = item.paymentIds.toSet();
    final targetDebts = allDebts
        .where((d) =>
            d.debtorId == item.debtorId &&
            d.recipientId == item.recipientId &&
            d.status != DebtStatus.dismissed)
        .toList();

    final maxAllowedAmount = targetDebts.fold<double>(0.0, (sum, d) {
      final removedFromDebt = d.payments
          .where((p) => paymentIdSet.contains(p.id))
          .fold<double>(0.0, (s, p) => s + p.amount);
      final restoredBalance =
          (d.remainingBalance + removedFromDebt).clamp(0.0, d.originalAmount);
      return sum + restoredBalance;
    });

    final effectiveMax =
        maxAllowedAmount > item.amount ? maxAllowedAmount : item.amount;

    DateTime selectedPaymentDate = item.recordedAt;
    final amountController = TextEditingController(
      text: item.amount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: item.note ?? '');
    final isDesktop = AppBreakpoints.isDesktop(context);

    Widget buildEditForm(BuildContext modalCtx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final parsedAmount =
              double.tryParse(amountController.text.trim()) ?? 0.0;
          final isValidAmount =
              parsedAmount > 0.001 && parsedAmount <= effectiveMax + 0.001;

          final now = DateTime.now();
          final isToday = _isSameDay(selectedPaymentDate, now);
          final isYesterday = _isSameDay(
            selectedPaymentDate,
            now.subtract(const Duration(days: 1)),
          );
          final formattedPaymentDate = isToday
              ? 'Today, ${DateFormat.yMMMd().format(selectedPaymentDate)}'
              : isYesterday
                  ? 'Yesterday, ${DateFormat.yMMMd().format(selectedPaymentDate)}'
                  : DateFormat.yMMMd().format(selectedPaymentDate);

          Future<void> pickPaymentDate() async {
            final currentNow = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: selectedPaymentDate.isAfter(currentNow)
                  ? currentNow
                  : selectedPaymentDate,
              firstDate: DateTime(2020),
              lastDate: currentNow,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accentPrimary,
                      onPrimary: AppColors.onAccentPrimary,
                      surface: AppColors.bgSurface,
                      onSurface: AppColors.textPrimary,
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: AppColors.bgSurface,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              setModalState(() {
                selectedPaymentDate = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  selectedPaymentDate.hour,
                  selectedPaymentDate.minute,
                  selectedPaymentDate.second,
                );
              });
            }
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Payment • ${debtor.displayName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Max payable for this member: ₱${effectiveMax.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount (₱)',
                    labelStyle:
                        GoogleFonts.inter(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAYMENT DATE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPaymentDateChip(
                          label: 'Today',
                          selected: isToday,
                          onTap: () => setModalState(
                            () => selectedPaymentDate = DateTime.now(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildPaymentDateChip(
                          label: 'Yesterday',
                          selected: isYesterday,
                          onTap: () => setModalState(
                            () => selectedPaymentDate = DateTime.now()
                                .subtract(const Duration(days: 1)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: pickPaymentDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !isToday
                              ? AppColors.accentPrimary.withValues(alpha: 0.45)
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.accentPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              formattedPaymentDate,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional, e.g. GCash ref #)',
                    labelStyle:
                        GoogleFonts.inter(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        type: NeonButtonType.danger,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(modalCtx);
                          await ref
                              .read(ledgerRepositoryProvider)
                              .updatePaymentHistoryItem(
                                item: item,
                                allDebts: allDebts,
                                newAmount: 0.0,
                                newDate: selectedPaymentDate,
                                newNote: null,
                                updatedBy: currentUser.id,
                              );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Deleted payment for ${debtor.displayName} and restored balance.',
                              ),
                              backgroundColor: AppColors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeonButton(
                        label: 'Save Changes',
                        icon: Icons.check_rounded,
                        type: NeonButtonType.mint,
                        onPressed: !isValidAmount
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final clampedAmount = parsedAmount
                                    .clamp(0.01, effectiveMax)
                                    .toDouble();
                                Navigator.pop(modalCtx);
                                await ref
                                    .read(ledgerRepositoryProvider)
                                    .updatePaymentHistoryItem(
                                      item: item,
                                      allDebts: allDebts,
                                      newAmount: clampedAmount,
                                      newDate: selectedPaymentDate,
                                      newNote: noteController.text.trim().isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                      updatedBy: currentUser.id,
                                    );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Updated payment for ${debtor.displayName} to ₱${clampedAmount.toStringAsFixed(0)}!',
                                    ),
                                    backgroundColor: AppColors.accentSuccess,
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: buildEditForm(ctx),
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
        child: buildEditForm(ctx),
      ),
    );
  }

  void _showRecordPaymentModal({
    required BuildContext context,
    required WidgetRef ref,
    required MemberLedgerSummary initialSummary,
    required List<MemberLedgerSummary> selectableSummaries,
    required AppUser Function(String) getUser,
    required AppUser currentUser,
  }) {
    MemberLedgerSummary selectedSummary = initialSummary;
    bool isPartialMode = false;
    DateTime selectedPaymentDate = DateTime.now();
    final amountController = TextEditingController(
      text: selectedSummary.toBeReceived.toStringAsFixed(0),
    );
    final noteController = TextEditingController();
    final isDesktop = AppBreakpoints.isDesktop(context);

    String summaryKey(MemberLedgerSummary s) =>
        '${s.debtorId}|${s.recipientId}|${s.isTransferred}';

    Widget buildForm(BuildContext modalCtx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final debtor = getUser(selectedSummary.debtorId);
          final maxBalance = selectedSummary.toBeReceived;
          final parsedAmount =
              double.tryParse(amountController.text.trim()) ?? 0.0;
          final effectivePayment =
              parsedAmount.clamp(0.0, maxBalance).toDouble();
          final remainingAfter =
              (maxBalance - effectivePayment).clamp(0.0, maxBalance);
          final isValidAmount =
              parsedAmount > 0.001 && parsedAmount <= maxBalance + 0.001;

          final now = DateTime.now();
          final isToday = _isSameDay(selectedPaymentDate, now);
          final isYesterday = _isSameDay(
            selectedPaymentDate,
            now.subtract(const Duration(days: 1)),
          );
          final formattedPaymentDate = isToday
              ? 'Today, ${DateFormat.yMMMd().format(selectedPaymentDate)}'
              : isYesterday
                  ? 'Yesterday, ${DateFormat.yMMMd().format(selectedPaymentDate)}'
                  : DateFormat.yMMMd().format(selectedPaymentDate);

          Future<void> pickPaymentDate() async {
            final currentNow = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: selectedPaymentDate.isAfter(currentNow)
                  ? currentNow
                  : selectedPaymentDate,
              firstDate: DateTime(2020),
              lastDate: currentNow,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accentPrimary,
                      onPrimary: AppColors.onAccentPrimary,
                      surface: AppColors.bgSurface,
                      onSurface: AppColors.textPrimary,
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: AppColors.bgSurface,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              setModalState(() {
                selectedPaymentDate = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  currentNow.hour,
                  currentNow.minute,
                  currentNow.second,
                );
              });
            }
          }

          void setPaymentAmount(double amount, {required bool partial}) {
            final clamped = amount.clamp(1.0, maxBalance);
            final formatted = clamped % 1 == 0
                ? clamped.toStringAsFixed(0)
                : clamped.toStringAsFixed(2);
            setModalState(() {
              isPartialMode = partial;
              amountController.text = formatted;
            });
          }

          final quickPartialAmounts = <({String label, double amount})>[];
          if (maxBalance > 50) {
            quickPartialAmounts.add((label: '₱50', amount: 50.0));
          }
          if (maxBalance >= 40) {
            final quarter = (maxBalance * 0.25).roundToDouble();
            final half = (maxBalance * 0.50).roundToDouble();
            final threeQuarter = (maxBalance * 0.75).roundToDouble();
            if (quarter > 0 && quarter < maxBalance) {
              quickPartialAmounts.add(
                (label: '25% (₱${quarter.toStringAsFixed(0)})', amount: quarter),
              );
            }
            if (half > 0 && half < maxBalance) {
              quickPartialAmounts.add(
                (label: '50% (₱${half.toStringAsFixed(0)})', amount: half),
              );
            }
            if (threeQuarter > 0 && threeQuarter < maxBalance) {
              quickPartialAmounts.add(
                (
                  label: '75% (₱${threeQuarter.toStringAsFixed(0)})',
                  amount: threeQuarter
                ),
              );
            }
          }

          return SingleChildScrollView(
            child: Column(
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
                  'To Be Received: ₱${maxBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (selectableSummaries.length > 1) ...[
                  const SizedBox(height: 14),
                  Text(
                    'MEMBER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: summaryKey(selectedSummary),
                    isExpanded: true,
                    dropdownColor: AppColors.bgSurfaceElevated,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgSurfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.borderDefault),
                      ),
                    ),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: selectableSummaries.map((s) {
                      final u = getUser(s.debtorId);
                      final suffix = s.isTransferred ? ' (Bounty)' : '';
                      return DropdownMenuItem<String>(
                        value: summaryKey(s),
                        child: Text(
                          '${u.displayName}$suffix — ₱${s.toBeReceived.toStringAsFixed(0)} to be received',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final found = selectableSummaries.firstWhere(
                        (s) => summaryKey(s) == val,
                        orElse: () => selectedSummary,
                      );
                      setModalState(() {
                        selectedSummary = found;
                        final targetAmt = isPartialMode
                            ? (found.toBeReceived * 0.5)
                                .roundToDouble()
                                .clamp(1.0, found.toBeReceived)
                            : found.toBeReceived;
                        amountController.text = targetAmt.toStringAsFixed(0);
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'PAYMENT TYPE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            setPaymentAmount(maxBalance, partial: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: !isPartialMode
                                ? AppColors.accentMint.withValues(alpha: 0.16)
                                : AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isPartialMode
                                  ? AppColors.accentMint
                                  : AppColors.borderDefault,
                              width: !isPartialMode ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: !isPartialMode
                                    ? AppColors.accentMint
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Full Payment',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: !isPartialMode
                                        ? AppColors.accentMint
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          final defaultPartial = maxBalance > 50
                              ? 50.0
                              : (maxBalance * 0.5)
                                  .roundToDouble()
                                  .clamp(1.0, maxBalance);
                          setPaymentAmount(defaultPartial, partial: true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isPartialMode
                                ? AppColors.accentPrimary.withValues(alpha: 0.16)
                                : AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPartialMode
                                  ? AppColors.accentPrimary
                                  : AppColors.borderDefault,
                              width: isPartialMode ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pie_chart_outline_rounded,
                                size: 16,
                                color: isPartialMode
                                    ? AppColors.accentPrimary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Partial Payment',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isPartialMode
                                        ? AppColors.accentPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isPartialMode && quickPartialAmounts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in quickPartialAmounts)
                        ActionChip(
                          label: Text(preset.label),
                          backgroundColor:
                              (effectivePayment - preset.amount).abs() < 0.5
                                  ? AppColors.accentPrimary
                                  : AppColors.bgSurfaceElevated,
                          side: BorderSide(
                            color:
                                (effectivePayment - preset.amount).abs() < 0.5
                                    ? AppColors.accentPrimary
                                    : AppColors.borderDefault,
                          ),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                (effectivePayment - preset.amount).abs() < 0.5
                                    ? AppColors.onAccentPrimary
                                    : AppColors.textPrimary,
                          ),
                          onPressed: () =>
                              setPaymentAmount(preset.amount, partial: true),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim()) ?? 0.0;
                    setModalState(() {
                      isPartialMode =
                          parsed > 0 && parsed < maxBalance - 0.001;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: isPartialMode
                        ? 'Partial Payment Amount (₱)'
                        : 'Payment Amount (₱)',
                    labelStyle:
                        GoogleFonts.inter(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAYMENT DATE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPaymentDateChip(
                          label: 'Today',
                          selected: isToday,
                          onTap: () => setModalState(
                            () => selectedPaymentDate = DateTime.now(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildPaymentDateChip(
                          label: 'Yesterday',
                          selected: isYesterday,
                          onTap: () => setModalState(
                            () => selectedPaymentDate = DateTime.now()
                                .subtract(const Duration(days: 1)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: pickPaymentDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !isToday
                              ? AppColors.accentPrimary.withValues(alpha: 0.45)
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.accentPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              formattedPaymentDate,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: remainingAfter <= 0.001
                          ? AppColors.accentMint.withValues(alpha: 0.35)
                          : AppColors.accentPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Paying Now',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₱${effectivePayment.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Remaining To Be Received',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            remainingAfter <= 0.001
                                ? '₱0 (Settled)'
                                : '₱${remainingAfter.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: remainingAfter <= 0.001
                                  ? AppColors.accentMint
                                  : AppColors.accentPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional, e.g. GCash ref #)',
                    labelStyle:
                        GoogleFonts.inter(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                NeonButton(
                  label: remainingAfter <= 0.001
                      ? 'Confirm Full Payment (₱${effectivePayment.toStringAsFixed(0)})'
                      : 'Record Partial Payment (₱${effectivePayment.toStringAsFixed(0)})',
                  icon: Icons.check_rounded,
                  type: NeonButtonType.mint,
                  width: double.infinity,
                  onPressed: !isValidAmount
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(modalCtx);
                          await ref
                              .read(ledgerRepositoryProvider)
                              .recordMemberPayment(
                                activeDebts: selectedSummary.activeDebts,
                                amount: effectivePayment,
                                recordedBy: currentUser.id,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                                paidAt: selectedPaymentDate,
                              );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                remainingAfter <= 0.001
                                    ? 'Recorded ₱${effectivePayment.toStringAsFixed(0)} full payment for ${debtor.displayName}!'
                                    : 'Recorded ₱${effectivePayment.toStringAsFixed(0)} partial payment for ${debtor.displayName} (₱${remainingAfter.toStringAsFixed(0)} to be received).',
                              ),
                              backgroundColor: AppColors.accentSuccess,
                            ),
                          );
                        },
                ),
              ],
            ),
          );
        },
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
            constraints: const BoxConstraints(maxWidth: 440),
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

  Widget _buildPaymentDateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.18)
              : AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showDismissDialog(
    BuildContext context,
    WidgetRef ref,
    MemberLedgerSummary summary,
    AppUser debtor,
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
          'Dismiss Transferred Balance?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            'As the recipient of this Keeper bounty, you have authority to forgive ${debtor.displayName}\'s remaining ₱${summary.toBeReceived.toStringAsFixed(0)} balance.',
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
              await ref
                  .read(ledgerRepositoryProvider)
                  .dismissMemberTransferredDebts(
                    activeDebts: summary.activeDebts,
                    dismissedBy: currentUser.id,
                    reason: 'Forgiven by bounty recipient',
                  );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Transferred balance dismissed.'),
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
