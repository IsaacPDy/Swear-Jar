import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsListProvider).valueOrNull ?? [];
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
          displayName: 'Member ($uid)',
          roles: const [UserRole.member],
          status: UserStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final filteredReports = reports.where((r) {
      if (_selectedFilter == 'pending') return r.isPending;
      if (_selectedFilter == 'confirmed') return r.isConfirmed;
      if (_selectedFilter == 'rejected') return r.isRejected;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report History & Review',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1120 : 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: isDesktop ? 14 : 10,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All (${reports.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Pending (${reports.where((r) => r.isPending).length})',
                        'pending',
                        highlight: reports.any((r) => r.isPending),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Confirmed', 'confirmed'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppColors.borderDefault, height: 1),
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 44,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reports found',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : isDesktop
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            itemCount: (filteredReports.length / 2).ceil(),
                            itemBuilder: (context, rowIndex) {
                              final firstIndex = rowIndex * 2;
                              final secondIndex = firstIndex + 1;
                              final firstReport = filteredReports[firstIndex];
                              final secondReport =
                                  secondIndex < filteredReports.length
                                      ? filteredReports[secondIndex]
                                      : null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: _buildReportCard(
                                          context: context,
                                          report: firstReport,
                                          accused: getUser(firstReport.accusedId),
                                          reporter:
                                              getUser(firstReport.reporterId),
                                          keeper: keeper,
                                          currentUser: currentUser,
                                          isKeeperOrAdmin: isKeeperOrAdmin,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: secondReport != null
                                            ? _buildReportCard(
                                                context: context,
                                                report: secondReport,
                                                accused: getUser(
                                                    secondReport.accusedId),
                                                reporter: getUser(
                                                    secondReport.reporterId),
                                                keeper: keeper,
                                                currentUser: currentUser,
                                                isKeeperOrAdmin: isKeeperOrAdmin,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildReportCard(
                                  context: context,
                                  report: report,
                                  accused: getUser(report.accusedId),
                                  reporter: getUser(report.reporterId),
                                  keeper: keeper,
                                  currentUser: currentUser,
                                  isKeeperOrAdmin: isKeeperOrAdmin,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required SwearReport report,
    required AppUser accused,
    required AppUser reporter,
    required AppUser? keeper,
    required AppUser? currentUser,
    required bool isKeeperOrAdmin,
  }) {
    final isKeeperAccused = accused.id == keeper?.id;

    return NeonCard(
      padding: const EdgeInsets.all(16),
      borderColor: report.isPending
          ? AppColors.accentWarning.withValues(alpha: 0.35)
          : AppColors.borderDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(user: accused, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                accused.displayName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isKeeperAccused) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPrimary
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.accentPrimary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'KEEPER',
                                  style: GoogleFonts.inter(
                                    color: AppColors.accentPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reported by ${reporter.displayName} • ${DateFormat.yMMMd().add_jm().format(report.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill.fromReport(report.status),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.record_voice_over_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${report.count} Swear(s) × ₱${report.rateApplied.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CurrencyText(
                      amount: report.totalAmount,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
              if (report.note != null && report.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '"${report.note}"',
                  style: GoogleFonts.inter(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (isKeeperAccused && report.isPending) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 16,
                        color: AppColors.accentPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keeper Swear Rule: Confirming will transfer Keeper\'s unpaid debts to ${reporter.displayName} and forgive reporter debt.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (report.isPending && isKeeperOrAdmin && currentUser != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'Reject',
                    type: NeonButtonType.danger,
                    icon: Icons.close_rounded,
                    onPressed: () =>
                        _confirmRejectDialog(context, report, currentUser),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeonButton(
                    label: 'Confirm Swear',
                    type: NeonButtonType.primary,
                    icon: Icons.check_rounded,
                    onPressed: () => _confirmApproveDialog(
                        context, report, currentUser, keeper, reporter),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {bool highlight = false}) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.accentPrimary,
      backgroundColor: highlight
          ? AppColors.accentWarning.withValues(alpha: 0.14)
          : AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: GoogleFonts.inter(
        color: isSelected
            ? Colors.white
            : (highlight ? AppColors.accentWarning : AppColors.textSecondary),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12.5,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.accentPrimary
            : (highlight
                ? AppColors.accentWarning.withValues(alpha: 0.35)
                : AppColors.borderDefault),
      ),
    );
  }

  void _confirmApproveDialog(
    BuildContext context,
    SwearReport report,
    AppUser currentUser,
    AppUser? keeper,
    AppUser reporter,
  ) {
    final isKeeperAccused = report.accusedId == keeper?.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          isKeeperAccused ? 'Confirm Keeper Swear?' : 'Confirm Swear Report?',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirming this report will lock in a ₱${report.totalAmount.toStringAsFixed(0)} penalty obligation.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              if (isKeeperAccused) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Keeper Swear Invariant:\n• Active Keeper debts transfer to ${reporter.displayName}.\n• ${reporter.displayName}\'s existing debt to Keeper is forgiven.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          NeonButton(
            label: 'Confirm Now',
            type: NeonButtonType.primary,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final debts = ref.read(debtsListProvider).valueOrNull ?? [];
              await ref.read(reportRepositoryProvider).confirmReport(
                    report: report,
                    activeKeeperId: keeper?.id ?? currentUser.id,
                    reviewerId: currentUser.id,
                    existingDebts: debts,
                  );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Swear confirmed! Obligation ledger updated.'),
                  backgroundColor: AppColors.accentSuccess,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmRejectDialog(
    BuildContext context,
    SwearReport report,
    AppUser currentUser,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Reject Report?',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: AppColors.accentError),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to reject this swear report? No debt will be created.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Optional rejection reason...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgSurfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          NeonButton(
            label: 'Reject Report',
            type: NeonButtonType.danger,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(reportRepositoryProvider).rejectReport(
                    report: report,
                    reviewerId: currentUser.id,
                    reason: reasonController.text.trim().isEmpty
                        ? null
                        : reasonController.text.trim(),
                  );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Report rejected.'),
                  backgroundColor: AppColors.accentError,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


