import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class ReportSwearScreen extends ConsumerStatefulWidget {
  final VoidCallback? onReportSubmitted;

  const ReportSwearScreen({super.key, this.onReportSubmitted});

  @override
  ConsumerState<ReportSwearScreen> createState() => _ReportSwearScreenState();
}

class _ReportSwearScreenState extends ConsumerState<ReportSwearScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedAccusedId;
  int _swearCount = 1;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(approvedUsersProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final config = ref.watch(systemConfigProvider).valueOrNull;
    final keeper = ref.watch(activeKeeperProvider);
    final isDesktop = AppBreakpoints.isDesktop(context);

    final currentRate = config?.currentRatePerSwear ?? 50.0;
    final totalConsequence = _swearCount * currentRate;

    if (_selectedAccusedId == null && users.isNotEmpty) {
      final other = users.firstWhere((u) => u.id != currentUser?.id,
          orElse: () => users.first);
      _selectedAccusedId = other.id;
    }

    final isKeeperSelected = _selectedAccusedId == keeper?.id;
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final isYesterday =
        _isSameDay(_selectedDate, now.subtract(const Duration(days: 1)));

    final jarEmblem = Center(
      child: RotationTransition(
        turns: _shakeAnimation,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 40,
            color: AppColors.accentPrimary,
          ),
        ),
      ),
    );

    final accusedSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHO COMMITTED THE SWEAR?',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        if (isDesktop)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final user in users)
                _buildUserSelectorTile(user, currentUser, isDesktop: true),
            ],
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final user in users)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _buildUserSelectorTile(user, currentUser,
                        isDesktop: false),
                  ),
              ],
            ),
          ),
        if (isKeeperSelected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'re reporting the Keeper! If confirmed, unpaid Keeper debts transfer to you and your debt to Keeper is forgiven!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    final dateAdjusterSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE OF SWEAR',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(14),
          onTap: () => _pickDate(context),
          borderColor: !isToday
              ? AppColors.accentPrimary.withValues(alpha: 0.45)
              : AppColors.borderDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? 'Today (${DateFormat.yMMMd().format(_selectedDate)})'
                              : isYesterday
                                  ? 'Yesterday (${DateFormat.yMMMd().format(_selectedDate)})'
                                  : DateFormat.yMMMMEEEEd()
                                      .format(_selectedDate),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to choose when the swear happened',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: AppColors.accentPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDateChip(
                    label: 'Today',
                    selected: isToday,
                    onTap: () => setState(() => _selectedDate = DateTime.now()),
                  ),
                  _buildDateChip(
                    label: 'Yesterday',
                    selected: isYesterday,
                    onTap: () => setState(() {
                      final y =
                          DateTime.now().subtract(const Duration(days: 1));
                      _selectedDate =
                          DateTime(y.year, y.month, y.day, y.hour, y.minute);
                    }),
                  ),
                  _buildDateChip(
                    label: 'Pick Date...',
                    selected: !isToday && !isYesterday,
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _pickDate(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final swearCountSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SWEAR COUNT (1–99)',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              'Tap number to type',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _swearCount > 1
                        ? () => setState(() => _swearCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 30),
                    color: AppColors.accentPrimary,
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showCustomCountDialog(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 96),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.45),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_swearCount',
                              style: GoogleFonts.outfit(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppColors.accentPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _swearCount < 99
                        ? () => setState(() => _swearCount++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline, size: 30),
                    color: AppColors.accentPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickButton('+1', () => _setCountOffset(1)),
                  _buildQuickButton('+2', () => _setCountOffset(2)),
                  _buildQuickButton('+5', () => _setCountOffset(5)),
                  _buildQuickButton(
                      'Max (99)', () => setState(() => _swearCount = 99)),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final noteSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTE / CONTEXT (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLength: 120,
          maxLines: isDesktop ? 3 : 1,
          decoration: InputDecoration(
            hintText: 'e.g., Screamed during Mario Kart tournament...',
            hintStyle:
                GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13.5),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentPrimary),
            ),
          ),
          style:
              GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13.5),
        ),
      ],
    );

    final summaryCard = NeonCard(
      backgroundColor: AppColors.bgSurface,
      borderColor: AppColors.accentPrimary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSEQUENCE RATE',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${currentRate.toStringAsFixed(0)} / swear',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL OBLIGATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(height: 2),
              CurrencyText(
                amount: totalConsequence,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );

    final submitButton = NeonButton(
      label: 'Submit Swear to Jar',
      icon: Icons.send_rounded,
      type: NeonButtonType.primary,
      width: double.infinity,
      isLoading: _isSubmitting,
      onPressed: _selectedAccusedId == null
          ? null
          : () => _handleSubmit(currentUser, currentRate),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report a Swear',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1080 : 600),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: isDesktop ? 24 : 16,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            accusedSection,
                            const SizedBox(height: 24),
                            dateAdjusterSection,
                            const SizedBox(height: 24),
                            noteSection,
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            jarEmblem,
                            const SizedBox(height: 20),
                            swearCountSection,
                            const SizedBox(height: 16),
                            summaryCard,
                            const SizedBox(height: 20),
                            submitButton,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      jarEmblem,
                      const SizedBox(height: 24),
                      accusedSection,
                      const SizedBox(height: 24),
                      dateAdjusterSection,
                      const SizedBox(height: 24),
                      swearCountSection,
                      const SizedBox(height: 24),
                      noteSection,
                      const SizedBox(height: 20),
                      summaryCard,
                      const SizedBox(height: 24),
                      submitButton,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.16)
              : AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color:
                    selected ? AppColors.accentPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
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
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.bgSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        );
      });
    }
  }

  void _showCustomCountDialog(BuildContext context) {
    final controller = TextEditingController(text: '$_swearCount');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Enter Swear Count',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the number of swears (1–99):',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgSurfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accentPrimary),
                  ),
                ),
                onSubmitted: (val) {
                  final parsed = int.tryParse(val.trim());
                  if (parsed != null && parsed >= 1) {
                    setState(() => _swearCount = parsed.clamp(1, 99));
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
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
            label: 'Set Count',
            type: NeonButtonType.primary,
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 1) {
                setState(() => _swearCount = parsed.clamp(1, 99));
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelectorTile(
    AppUser user,
    AppUser? currentUser, {
    required bool isDesktop,
  }) {
    final isSelected = _selectedAccusedId == user.id;

    return InkWell(
      onTap: () => setState(() => _selectedAccusedId = user.id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isDesktop ? 124 : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.14)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.borderDefault,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(user: user, size: 44),
            const SizedBox(height: 8),
            Text(
              user.id == currentUser?.id
                  ? 'Myself'
                  : user.displayName.split(' ').first,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.isKeeper ? 'Keeper' : 'Member',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color:
                    user.isKeeper ? AppColors.accentPrimary : AppColors.textMuted,
                fontWeight: user.isKeeper ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _setCountOffset(int offset) {
    setState(() {
      _swearCount = (_swearCount + offset).clamp(1, 99);
    });
  }

  Future<void> _handleSubmit(AppUser? currentUser, double currentRate) async {
    if (currentUser == null || _selectedAccusedId == null) return;

    setState(() => _isSubmitting = true);
    await _shakeController.forward(from: 0.0);

    final note = _noteController.text.trim();

    await ref.read(reportRepositoryProvider).submitReport(
          reporterId: currentUser.id,
          accusedId: _selectedAccusedId!,
          count: _swearCount,
          note: note.isEmpty ? null : note,
          rateApplied: currentRate,
          swearDate: _selectedDate,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swear reported! Sent to Keeper for confirmation.'),
          backgroundColor: AppColors.accentSuccess,
        ),
      );
      _noteController.clear();
      setState(() {
        _swearCount = 1;
        _selectedDate = DateTime.now();
      });
      widget.onReportSubmitted?.call();
    }
  }
}

