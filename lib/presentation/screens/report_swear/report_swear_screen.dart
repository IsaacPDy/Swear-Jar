import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(approvedUsersProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final config = ref.watch(systemConfigProvider).valueOrNull;
    final keeper = ref.watch(activeKeeperProvider);

    final currentRate = config?.currentRatePerSwear ?? 50.0;
    final totalConsequence = _swearCount * currentRate;

    if (_selectedAccusedId == null && users.isNotEmpty) {
      final other = users.firstWhere((u) => u.id != currentUser?.id, orElse: () => users.first);
      _selectedAccusedId = other.id;
    }

    final isKeeperSelected = _selectedAccusedId == keeper?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Report a Swear', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: RotationTransition(
                    turns: _shakeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentPrimary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.accentGlow,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        size: 48,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'WHO COMMITTED THE SWEAR?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final user in users) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedAccusedId = user.id);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedAccusedId == user.id
                                    ? AppColors.accentPrimary.withValues(alpha: 0.18)
                                    : AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedAccusedId == user.id
                                      ? AppColors.accentPrimary
                                      : AppColors.borderDefault,
                                  width: _selectedAccusedId == user.id ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  UserAvatar(user: user, size: 48),
                                  const SizedBox(height: 8),
                                  Text(
                                    user.id == currentUser?.id ? 'Myself' : user.displayName.split(' ').first,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _selectedAccusedId == user.id
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (user.isKeeper)
                                    Text(
                                      '👑 Keeper',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.accentPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isKeeperSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on, color: AppColors.accentPrimary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'re reporting the Keeper! If confirmed, unpaid Keeper debts transfer to you and your debt to Keeper is forgiven!',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'SWEAR COUNT (1–99)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                NeonCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _swearCount > 1 ? () => setState(() => _swearCount--) : null,
                            icon: const Icon(Icons.remove_circle_outline, size: 32),
                            color: AppColors.accentPrimary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderDefault),
                            ),
                            child: Text(
                              '$_swearCount',
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _swearCount < 99 ? () => setState(() => _swearCount++) : null,
                            icon: const Icon(Icons.add_circle_outline, size: 32),
                            color: AppColors.accentPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuickButton('+1', () => _setCountOffset(1)),
                          const SizedBox(width: 8),
                          _buildQuickButton('+2', () => _setCountOffset(2)),
                          const SizedBox(width: 8),
                          _buildQuickButton('+5', () => _setCountOffset(5)),
                          const SizedBox(width: 8),
                          _buildQuickButton('Max (99)', () => setState(() => _swearCount = 99)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NOTE / CONTEXT (OPTIONAL)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLength: 120,
                  decoration: InputDecoration(
                    hintText: 'e.g., Screamed during Mario Kart tournament...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentPrimary),
                    ),
                  ),
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                NeonCard(
                  backgroundColor: AppColors.bgSurfaceElevated,
                  borderColor: AppColors.accentPrimary.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONSEQUENCE RATE',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                          Text(
                            '₱${currentRate.toStringAsFixed(0)} / swear',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL OBLIGATION',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentPrimary),
                          ),
                          CurrencyText(
                            amount: totalConsequence,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NeonButton(
                  label: 'Submit Swear to Jar',
                  icon: Icons.send_rounded,
                  type: NeonButtonType.primary,
                  width: double.infinity,
                  isLoading: _isSubmitting,
                  onPressed: _selectedAccusedId == null
                      ? null
                      : () => _handleSubmit(currentUser, currentRate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
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
      setState(() => _swearCount = 1);
      widget.onReportSubmitted?.call();
    }
  }
}
