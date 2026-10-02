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
  final FocusNode _noteFocusNode = FocusNode();
  final Map<String, int> _selectedSwearCounts = {};
  String _selectedLanguageId = 'english';
  bool _showCustomNoteField = false;
  bool _isSubmitting = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  int get _templateSwearsTotal =>
      _selectedSwearCounts.values.fold(0, (sum, count) => sum + count);

  int get _minSwearCount =>
      _templateSwearsTotal > 0 ? _templateSwearsTotal : 1;

  void _adjustTemplateSwearCount(String swear, int delta) {
    setState(() {
      final oldTemplateTotal = _templateSwearsTotal;
      final overage = oldTemplateTotal == 0
          ? (_swearCount - 1).clamp(0, 99)
          : (_swearCount - oldTemplateTotal).clamp(0, 99);

      final currentForSwear = _selectedSwearCounts[swear] ?? 0;
      final nextForSwear = (currentForSwear + delta).clamp(0, 99);

      if (nextForSwear <= 0) {
        _selectedSwearCounts.remove(swear);
      } else {
        _selectedSwearCounts[swear] = nextForSwear;
      }

      final newTemplateTotal = _templateSwearsTotal;
      if (newTemplateTotal > 0) {
        _swearCount = (newTemplateTotal + overage).clamp(newTemplateTotal, 99);
      } else {
        _swearCount = (1 + overage).clamp(1, 99);
      }
    });
  }

  void _clearTemplateSwears() {
    setState(() {
      final oldTemplateTotal = _templateSwearsTotal;
      final overage = oldTemplateTotal == 0
          ? (_swearCount - 1).clamp(0, 99)
          : (_swearCount - oldTemplateTotal).clamp(0, 99);
      _selectedSwearCounts.clear();
      _swearCount = (1 + overage).clamp(1, 99);
    });
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.06), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.04), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.04), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _noteController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _cleanDisplayName(AppUser user) {
    final base = user.displayName.split('(').first.trim();
    return base.isNotEmpty ? base : user.displayName;
  }

  String _previewQuoteText() {
    if (_selectedSwearCounts.isNotEmpty) {
      final joined = _selectedSwearCounts.entries
          .map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key)
          .join(', ');
      return '"$joined"';
    }
    final note = _noteController.text.trim();
    if (note.isNotEmpty) {
      return '"$note"';
    }
    return '"Unspecified swear"';
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(approvedUsersProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final config = ref.watch(systemConfigProvider).valueOrNull;
    final keeper = ref.watch(activeKeeperProvider);
    final isDesktop = AppBreakpoints.isDesktop(context);

    final swearLanguages = config?.swearLanguages ?? const <SwearLanguage>[];
    if (_selectedLanguageId != 'all' &&
        !swearLanguages.any((l) => l.id == _selectedLanguageId)) {
      _selectedLanguageId =
          swearLanguages.isNotEmpty ? swearLanguages.first.id : 'all';
    }

    final currentRate = config?.currentRatePerSwear ?? 50.0;
    final totalConsequence = _swearCount * currentRate;

    if (_selectedAccusedId == null && users.isNotEmpty) {
      final other = users.firstWhere(
        (u) => u.id != currentUser?.id,
        orElse: () => users.first,
      );
      _selectedAccusedId = other.id;
    }

    final selectedAccusedUser = users.isNotEmpty
        ? users.firstWhere(
            (u) => u.id == _selectedAccusedId,
            orElse: () => users.first,
          )
        : currentUser;

    final isKeeperSelected = _selectedAccusedId == keeper?.id;
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final isYesterday =
        _isSameDay(_selectedDate, now.subtract(const Duration(days: 1)));

    // Top Header matching reference image ("REPORT" overline + "Report a Swear" + subtitle + tilted Swear Jar with coins & sparkles)
    final pageHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REPORT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.accentGoldMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Report a Swear',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 32 : 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Log the incident and add it to the ledger.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        RotationTransition(
          turns: _shakeAnimation,
          child: SwearJarHeroIllustration(
            width: isDesktop ? 136 : 104,
            height: isDesktop ? 92 : 76,
          ),
        ),
      ],
    );

    // STEP 1: Who swore?
    final step1WhoSwore = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const StepNumberBadge(number: 1, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Who swore?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Select the person who said it.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = isDesktop ? 5 : 3;
            const spacing = 10.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final user in users)
                  SizedBox(
                    width: tileWidth.clamp(86.0, 160.0),
                    child: _buildUserSelectorTile(user, currentUser),
                  ),
              ],
            );
          },
        ),
        if (isKeeperSelected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.accentPrimary,
                  size: 18,
                ),
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

    // STEP 2: Which word did they say?
    final visibleLanguages = _selectedLanguageId == 'all'
        ? swearLanguages
        : swearLanguages.where((l) => l.id == _selectedLanguageId).toList();

    final activeLangName = _selectedLanguageId == 'all'
        ? 'All Languages'
        : (swearLanguages
                .where((l) => l.id == _selectedLanguageId)
                .firstOrNull
                ?.name ??
            'English');

    final step2WhichWord = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const StepNumberBadge(number: 2, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Which word did they say?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Select from the list of swears.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (swearLanguages.isNotEmpty)
              PopupMenuButton<String>(
                tooltip: 'Select language',
                color: AppColors.bgSurfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.borderDefault),
                ),
                onSelected: (val) => setState(() => _selectedLanguageId = val),
                itemBuilder: (context) => [
                  for (final lang in swearLanguages)
                    PopupMenuItem<String>(
                      value: lang.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 16,
                            color: _selectedLanguageId == lang.id
                                ? AppColors.accentMint
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lang.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: _selectedLanguageId == lang.id
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (swearLanguages.length > 1)
                    PopupMenuItem<String>(
                      value: 'all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.apps_rounded,
                            size: 16,
                            color: _selectedLanguageId == 'all'
                                ? AppColors.accentMint
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All Languages',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: _selectedLanguageId == 'all'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 16,
                        color: AppColors.accentMint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activeLangName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // When additional custom languages (>2) are configured by Admin, also show quick language tabs
        if (swearLanguages.length > 2) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: _buildDateChip(
                    label: 'All',
                    selected: _selectedLanguageId == 'all',
                    onTap: () => setState(() => _selectedLanguageId = 'all'),
                  ),
                ),
                for (final lang in swearLanguages)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _buildDateChip(
                      label: lang.name,
                      selected: _selectedLanguageId == lang.id,
                      onTap: () =>
                          setState(() => _selectedLanguageId = lang.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = isDesktop ? 5 : 3;
            const spacing = 10.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;

            final allVisibleSwears = <String>[];
            for (final lang in visibleLanguages) {
              for (final s in lang.swears) {
                if (!allVisibleSwears.contains(s)) {
                  allVisibleSwears.add(s);
                }
              }
            }

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final swear in allVisibleSwears)
                  SizedBox(
                    width: tileWidth.clamp(84.0, 180.0),
                    child: _buildSwearGridTile(swear),
                  ),
                SizedBox(
                  width: tileWidth.clamp(84.0, 180.0),
                  child: _buildOtherTile(),
                ),
              ],
            );
          },
        ),
        if (_selectedSwearCounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Selected:',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    for (final entry in _selectedSwearCounts.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () =>
                                  _adjustTemplateSwearCount(entry.key, -1),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _swearCount < 99
                                  ? () =>
                                      _adjustTemplateSwearCount(entry.key, 1)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0, vertical: 1.0),
                                child: Text(
                                  '${entry.key} ×${entry.value}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentPrimary,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _swearCount < 99
                                  ? () =>
                                      _adjustTemplateSwearCount(entry.key, 1)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 13,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: _clearTemplateSwears,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Clear ($_templateSwearsTotal)',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentError,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_showCustomNoteField || _noteController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            focusNode: _noteFocusNode,
            maxLength: 120,
            maxLines: 1,
            decoration: InputDecoration(
              hintText:
                  'Type custom word or incident note (e.g., Mario Kart rage)...',
              hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 13),
              counterText: '',
              filled: true,
              fillColor: AppColors.bgSurfaceElevated,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              suffixIcon: _noteController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 16, color: AppColors.textMuted),
                      onPressed: () {
                        _noteController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            style:
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13.5),
          ),
        ],
      ],
    );

    // STEP 3: When did it happen?
    final formattedDateLabel = isToday
        ? 'Today (${DateFormat.yMMMd().format(_selectedDate)})'
        : isYesterday
            ? 'Yesterday (${DateFormat.yMMMd().format(_selectedDate)})'
            : DateFormat.yMMMd().format(_selectedDate);

    final step3WhenDidItHappen = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const StepNumberBadge(number: 3, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When did it happen?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Select the date.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceSubtle,
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
                    size: 18,
                    color: AppColors.accentPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formattedDateLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final submitButton = NeonButton(
      label: 'Add to Ledger',
      icon: Icons.send_rounded,
      type: NeonButtonType.primary,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      isLoading: _isSubmitting,
      onPressed: _selectedAccusedId == null
          ? null
          : () => _handleSubmit(currentUser, currentRate),
    );

    final mainLeftStepsCard = NeonCard(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          step1WhoSwore,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: AppColors.borderDefault),
          ),
          step2WhichWord,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: AppColors.borderDefault),
          ),
          step3WhenDidItHappen,
          const SizedBox(height: 22),
          submitButton,
        ],
      ),
    );

    // RIGHT PANEL 1: Preview Card
    final previewCard = NeonCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 19,
                    color: AppColors.accentPrimary,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Preview',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: CurrencyText(
                  amount: totalConsequence,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedAccusedUser != null)
                  Row(
                    children: [
                      UserAvatar(user: selectedAccusedUser, size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cleanDisplayName(selectedAccusedUser),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _previewQuoteText(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppColors.borderDefault),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.accentPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMd().format(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Date',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // RIGHT PANEL 2: Swear count for this report Card
    final swearCountCard = NeonCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 22,
                  color: AppColors.accentMint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Swear count for this report',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'How many times was this word said?',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _swearCount > _minSwearCount
                    ? () => setState(() => _swearCount--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 36),
                color: AppColors.accentMint,
                disabledColor: AppColors.accentMint.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showCustomCountDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 112, minHeight: 62),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152228),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.borderMint,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_swearCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.accentMint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _swearCount < 99
                    ? () => setState(() => _swearCount++)
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 36),
                color: AppColors.accentMint,
                disabledColor: AppColors.accentMint.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (_templateSwearsTotal > 0) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Minimum $_templateSwearsTotal from selected swear templates'
                '${_swearCount > _templateSwearsTotal ? " (+${_swearCount - _templateSwearsTotal} extra)" : ""}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.accentMint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickButton('+1', () => _setCountOffset(1)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickButton('+2', () => _setCountOffset(2)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickButton('+5', () => _setCountOffset(5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildQuickButton(
                  'Max (99)',
                  () => setState(() => _swearCount = 99),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_rounded,
                    size: 16,
                    color: AppColors.accentMint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can also tap the number to type a custom amount if the word isn\'t on the list or was said more times.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1140 : 600),
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
                          flex: 65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              pageHeader,
                              const SizedBox(height: 14),
                              mainLeftStepsCard,
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 35,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 38),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                previewCard,
                                const SizedBox(height: 18),
                                swearCountCard,
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pageHeader,
                        const SizedBox(height: 14),
                        mainLeftStepsCard,
                        const SizedBox(height: 16),
                        swearCountCard,
                        const SizedBox(height: 16),
                        previewCard,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwearGridTile(String swear) {
    final count = _selectedSwearCounts[swear] ?? 0;
    final isSelected = count > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // If already selected once and user taps, toggle off if count == 1 or allow incrementing via Selected row;
          // Wait: let's make tapping an unselected swear select it (+1), and tapping a selected swear toggle it off if count == 1, or increment if tapped on the + badge.
          // Even better: tapping the tile increments (+1) or toggles? Let's check: in widget_test.dart:
          // await tester.tap(find.text('Carajo')); -> +1
          // await tester.tap(find.text('Mierda')); -> +1
          // await tester.tap(find.text('Mierda ×1').first); -> +1 (becomes 2)
          // And what if a user wants to deselect a single word by tapping it or its remove button?
          // If count == 0 -> _adjustTemplateSwearCount(swear, 1).
          // If count > 0 -> _adjustTemplateSwearCount(swear, -1) when tapping the tile, while tapping 'Mierda ×1' in the Selected bar increments it!
          if (!isSelected) {
            _adjustTemplateSwearCount(swear, 1);
          } else {
            _adjustTemplateSwearCount(swear, -1);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.bgSurfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPrimary
                  : AppColors.borderDefault,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            count > 1 ? '$swear (×$count)' : swear,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.onAccentPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherTile() {
    final isActive = _showCustomNoteField || _noteController.text.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _showCustomNoteField = !_showCustomNoteField;
          });
          if (_showCustomNoteField) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) _noteFocusNode.requestFocus();
            });
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accentPrimary.withValues(alpha: 0.16)
                : AppColors.bgSurfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isActive ? AppColors.accentPrimary : AppColors.borderDefault,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: isActive
                    ? AppColors.accentPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Other',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppColors.accentPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
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
              ? AppColors.accentPrimary.withValues(alpha: 0.18)
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
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
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
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
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
                _templateSwearsTotal > 0
                    ? 'Enter the number of swears ($_minSwearCount–99):'
                    : 'Enter the number of swears (1–99):',
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
                style: GoogleFonts.plusJakartaSans(
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
                    borderSide:
                        const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.accentPrimary),
                  ),
                ),
                onSubmitted: (val) {
                  final parsed = int.tryParse(val.trim());
                  if (parsed != null && parsed >= 1) {
                    setState(
                        () => _swearCount = parsed.clamp(_minSwearCount, 99));
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
                setState(() => _swearCount = parsed.clamp(_minSwearCount, 99));
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelectorTile(AppUser user, AppUser? currentUser) {
    final isSelected = _selectedAccusedId == user.id;
    final cleanFirst = _cleanDisplayName(user).split(' ').first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedAccusedId = user.id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF17202A)
                : AppColors.bgSurfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.accentPrimary : AppColors.borderDefault,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(user: user, size: 44, showBadge: false),
              const SizedBox(height: 10),
              Text(
                cleanFirst,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDefault),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _setCountOffset(int offset) {
    setState(() {
      _swearCount = (_swearCount + offset).clamp(_minSwearCount, 99);
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
          swearBreakdown: Map<String, int>.from(_selectedSwearCounts),
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
        _selectedSwearCounts.clear();
        _swearCount = 1;
        _selectedDate = DateTime.now();
        _showCustomNoteField = false;
      });
      widget.onReportSubmitted?.call();
    }
  }
}
