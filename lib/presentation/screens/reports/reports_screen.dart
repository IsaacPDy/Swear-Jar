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

    final filteredReports = reports.where((r) {
      if (_selectedFilter == 'pending') return r.isPending;
      if (_selectedFilter == 'confirmed') return r.isConfirmed;
      if (_selectedFilter == 'rejected') return r.isRejected;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Report History & Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
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
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          final accused = getUser(report.accusedId);
                          final reporter = getUser(report.reporterId);
                          final isKeeperAccused = accused.id == keeper?.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: NeonCard(
                              padding: const EdgeInsets.all(16),
                              borderColor: report.isPending
                                  ? AppColors.accentWarning.withValues(alpha: 0.4)
                                  : AppColors.borderDefault,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      UserAvatar(user: accused, size: 44),
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
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (isKeeperAccused) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentPrimary.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'KEEPER',
                                                      style: GoogleFonts.inter(
                                                        color: AppColors.accentPrimary,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
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
                                      StatusPill.fromReport(report.status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgSurfaceElevated,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.record_voice_over, size: 16, color: AppColors.accentPrimary),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${report.count} Swear(s) × ₱${report.rateApplied.toStringAsFixed(0)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        CurrencyText(
                                          amount: report.totalAmount,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentPrimary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (report.note != null && report.note!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
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
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentPrimary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.accentPrimary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Keeper Swear Rule: Confirming will transfer Keeper\'s unpaid debts to ${reporter.displayName} and forgive reporter debt!',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.accentPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (report.isPending && isKeeperOrAdmin && currentUser != null) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: NeonButton(
                                            label: 'Reject',
                                            type: NeonButtonType.danger,
                                            icon: Icons.close,
                                            onPressed: () => _confirmRejectDialog(context, report, currentUser),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: NeonButton(
                                            label: 'Confirm Swear',
                                            type: NeonButtonType.primary,
                                            icon: Icons.check,
                                            onPressed: () => _confirmApproveDialog(context, report, currentUser, keeper, reporter),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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

  Widget _buildFilterChip(String label, String value, {bool highlight = false}) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.accentPrimary,
      backgroundColor: highlight ? AppColors.accentWarning.withValues(alpha: 0.2) : AppColors.bgSurfaceElevated,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : (highlight ? AppColors.accentWarning : AppColors.textSecondary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.accentPrimary
            : (highlight ? AppColors.accentWarning.withValues(alpha: 0.4) : AppColors.borderDefault),
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
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isKeeperAccused ? 'Confirm Keeper Swear?' : 'Confirm Swear Report?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⚡ Keeper Swear Invariant:\n• Active Keeper debts transfer to ${reporter.displayName}.\n• ${reporter.displayName}\'s existing debt to Keeper is forgiven.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.accentPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Report?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentError),
        ),
        content: Column(
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
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
                    reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
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
