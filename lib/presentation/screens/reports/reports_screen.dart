import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                          'Swear Date: ${DateFormat.yMMMd().format(report.swearDate)} • Reported by ${reporter.displayName}',
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isKeeperOrAdmin
                      ? () => _showEditReportDialog(context, report)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isKeeperOrAdmin
                            ? AppColors.accentPrimary.withValues(alpha: 0.35)
                            : AppColors.borderSubtle,
                      ),
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
                              if (isKeeperOrAdmin) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: AppColors.accentPrimary,
                                ),
                              ],
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
          if (isKeeperOrAdmin && currentUser != null) ...[
            const SizedBox(height: 14),
            if (report.isPending) ...[
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeonButton(
                      label: 'Confirm',
                      type: NeonButtonType.primary,
                      icon: Icons.check_rounded,
                      onPressed: () => _confirmApproveDialog(
                          context, report, currentUser, keeper, reporter),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'Edit / Audit',
                    type: NeonButtonType.secondary,
                    icon: Icons.edit_note_rounded,
                    onPressed: () => _showEditReportDialog(context, report),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeonButton(
                    label: 'Delete',
                    type: NeonButtonType.danger,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _confirmDeleteDialog(context, report),
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

  void _showEditReportDialog(BuildContext context, SwearReport report) {
    final approvedUsers = ref.read(approvedUsersProvider);
    String selectedAccusedId = report.accusedId;
    int editedCount = report.count;
    DateTime editedDate = report.swearDate;
    final countController = TextEditingController(text: '${report.count}');
    final noteController = TextEditingController(text: report.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final newTotal = editedCount * report.rateApplied;

            void syncCountFromButtons(int newCount) {
              final clamped = newCount.clamp(1, 99);
              setModalState(() {
                editedCount = clamped;
                countController.text = '$clamped';
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.borderDefault),
              ),
              title: Text(
                'Audit & Adjust Report',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report.isConfirmed)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentPrimary
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.accentPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This report is confirmed. Saving changes will automatically update its linked ledger debt and all-time swears.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'ACCUSED MEMBER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: approvedUsers
                                .any((u) => u.id == selectedAccusedId)
                            ? selectedAccusedId
                            : (approvedUsers.isNotEmpty
                                ? approvedUsers.first.id
                                : null),
                        dropdownColor: AppColors.bgSurfaceElevated,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.bgSurfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.borderDefault),
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
                          fontWeight: FontWeight.w500,
                        ),
                        items: approvedUsers
                            .map(
                              (u) => DropdownMenuItem<String>(
                                value: u.id,
                                child: Text(u.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedAccusedId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DATE OF SWEAR',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate:
                                editedDate.isAfter(now) ? now : editedDate,
                            firstDate: DateTime(2020),
                            lastDate: now,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.accentPrimary,
                                    onPrimary: Colors.white,
                                    surface: AppColors.bgSurface,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              editedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                editedDate.hour,
                                editedDate.minute,
                              );
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDefault),
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
                                  DateFormat.yMMMMEEEEd().format(editedDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.edit_calendar_outlined,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SWEAR COUNT (1–99)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            onPressed: editedCount > 1
                                ? () => syncCountFromButtons(editedCount - 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.accentPrimary,
                          ),
                          Expanded(
                            child: TextField(
                              controller: countController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.bgSurfaceElevated,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderDefault),
                                ),
                              ),
                              onChanged: (val) {
                                final parsed = int.tryParse(val.trim());
                                if (parsed != null && parsed >= 1) {
                                  setModalState(
                                      () => editedCount = parsed.clamp(1, 99));
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: editedCount < 99
                                ? () => syncCountFromButtons(editedCount + 1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.accentPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Updated Total: ₱${newTotal.toStringAsFixed(0)} (₱${report.rateApplied.toStringAsFixed(0)} / swear)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NOTE / CONTEXT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        maxLength: 120,
                        decoration: InputDecoration(
                          hintText: 'Optional note...',
                          hintStyle: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.bgSurfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.borderDefault),
                          ),
                        ),
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: AppColors.textMuted)),
                ),
                NeonButton(
                  label: 'Save Changes',
                  type: NeonButtonType.primary,
                  icon: Icons.check_rounded,
                  onPressed: () async {
                    final parsed = int.tryParse(countController.text.trim());
                    final finalCount =
                        (parsed != null && parsed >= 1) ? parsed.clamp(1, 99) : editedCount;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final debts = ref.read(debtsListProvider).valueOrNull ?? [];
                    await ref.read(reportRepositoryProvider).updateReport(
                          report: report,
                          accusedId: selectedAccusedId,
                          count: finalCount,
                          swearDate: editedDate,
                          note: noteController.text.trim(),
                          existingDebts: debts,
                        );
                    messenger.showSnackBar(
                      const SnackBar(
                        content:
                            Text('Report & ledger updated successfully!'),
                        backgroundColor: AppColors.accentSuccess,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDialog(BuildContext context, SwearReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Delete Report Permanently?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: AppColors.accentError,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            report.isConfirmed
                ? 'Deleting this confirmed report will permanently remove it, delete its linked ₱${report.totalAmount.toStringAsFixed(0)} debt obligation from the ledger, and deduct ${report.count} swear(s) from the All-Time Swears counter.'
                : 'Are you sure you want to permanently delete this report from the history?',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          NeonButton(
            label: 'Delete Report',
            type: NeonButtonType.danger,
            icon: Icons.delete_outline_rounded,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final debts = ref.read(debtsListProvider).valueOrNull ?? [];
              await ref.read(reportRepositoryProvider).deleteReport(
                    report: report,
                    existingDebts: debts,
                  );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Report deleted from ledger.'),
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


