import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _rateController = TextEditingController();
  final _compensationController = TextEditingController();
  final _languageController = TextEditingController();
  final _initialSwearsController = TextEditingController();
  final Map<String, TextEditingController> _swearControllers = {};

  @override
  void initState() {
    super.initState();
    final config = ref.read(systemConfigProvider).valueOrNull;
    if (config != null) {
      _rateController.text = config.currentRatePerSwear.toStringAsFixed(0);
      _compensationController.text =
          config.currentCompensationPerSwear.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _compensationController.dispose();
    _languageController.dispose();
    _initialSwearsController.dispose();
    for (final c in _swearControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getSwearController(String langId) {
    return _swearControllers.putIfAbsent(langId, () => TextEditingController());
  }

  List<String> _parseSwearsInput(String raw) {
    final result = <String>[];
    for (final part in raw.split(RegExp(r'[,\n]+'))) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty &&
          !result.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
        result.add(trimmed);
      }
    }
    return result;
  }

  Future<void> _addLanguage(List<SwearLanguage> currentLanguages) async {
    final name = _languageController.text.trim();
    final initialSwears = _parseSwearsInput(_initialSwearsController.text);
    if (name.isEmpty) return;

    final existingIndex = currentLanguages.indexWhere(
      (l) => l.name.toLowerCase() == name.toLowerCase(),
    );
    if (existingIndex >= 0) {
      if (initialSwears.isNotEmpty) {
        final existingLang = currentLanguages[existingIndex];
        final merged = List<String>.from(existingLang.swears);
        for (final s in initialSwears) {
          if (!merged.any((e) => e.toLowerCase() == s.toLowerCase())) {
            merged.add(s);
          }
        }
        final updated = List<SwearLanguage>.from(currentLanguages);
        updated[existingIndex] = existingLang.copyWith(swears: merged);
        _languageController.clear();
        _initialSwearsController.clear();
        await ref.read(configRepositoryProvider).updateSwearLanguages(updated);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language "$name" already exists.'),
          backgroundColor: AppColors.accentWarning,
        ),
      );
      return;
    }

    final id =
        '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
    final updated = [
      ...currentLanguages,
      SwearLanguage(id: id, name: name, swears: initialSwears),
    ];
    _languageController.clear();
    _initialSwearsController.clear();
    await ref.read(configRepositoryProvider).updateSwearLanguages(updated);
  }

  Future<void> _removeLanguage(
    List<SwearLanguage> currentLanguages,
    String langId,
  ) async {
    final updated = currentLanguages.where((l) => l.id != langId).toList();
    _swearControllers.remove(langId)?.dispose();
    await ref.read(configRepositoryProvider).updateSwearLanguages(updated);
  }

  Future<void> _addSwearsToLanguage(
    List<SwearLanguage> currentLanguages,
    SwearLanguage lang,
  ) async {
    final controller = _getSwearController(lang.id);
    final raw = controller.text.trim();
    if (raw.isEmpty) return;

    final newSwears = _parseSwearsInput(raw);
    if (newSwears.isEmpty) return;

    final mergedSwears = List<String>.from(lang.swears);
    for (final s in newSwears) {
      final alreadyIn = mergedSwears.any(
        (existing) => existing.toLowerCase() == s.toLowerCase(),
      );
      if (!alreadyIn) {
        mergedSwears.add(s);
      }
    }

    final updated = currentLanguages.map((l) {
      if (l.id == lang.id) {
        return l.copyWith(swears: mergedSwears);
      }
      return l;
    }).toList();

    controller.clear();
    await ref.read(configRepositoryProvider).updateSwearLanguages(updated);
  }

  Future<void> _removeSwearFromLanguage(
    List<SwearLanguage> currentLanguages,
    SwearLanguage lang,
    String swear,
  ) async {
    final updatedSwears = lang.swears.where((s) => s != swear).toList();
    final updated = currentLanguages.map((l) {
      if (l.id == lang.id) {
        return l.copyWith(swears: updatedSwears);
      }
      return l;
    }).toList();

    await ref.read(configRepositoryProvider).updateSwearLanguages(updated);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final pendingUsers = ref.watch(pendingUsersProvider);
    final approvedUsers = ref.watch(approvedUsersProvider);
    final keeper = ref.watch(activeKeeperProvider);
    final config = ref.watch(systemConfigProvider).valueOrNull;
    final swearLanguages = config?.swearLanguages ?? const <SwearLanguage>[];
    final reports = ref.watch(reportsListProvider).valueOrNull ?? [];
    final debts = ref.watch(debtsListProvider).valueOrNull ?? [];
    final isDesktop = AppBreakpoints.isDesktop(context);

    final pendingApprovalsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_add_outlined,
                color: AppColors.accentWarning, size: 18),
            const SizedBox(width: 8),
            Text(
              'PENDING GOOGLE SIGN-INS (${pendingUsers.length})',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.accentWarning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pendingUsers.isEmpty)
          NeonCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No pending Google sign-ins.',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          for (final user in pendingUsers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: NeonCard(
                padding: const EdgeInsets.all(14),
                borderColor: AppColors.accentWarning.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(user: user, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (user.email.isNotEmpty)
                                Text(
                                  user.email,
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        NeonButton(
                          label: 'Reject',
                          type: NeonButtonType.danger,
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref
                                .read(userRepositoryProvider)
                                .rejectUser(user.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Dismissed sign-in request from ${user.displayName}. They can sign in again to request access.'),
                                backgroundColor: AppColors.accentWarning,
                              ),
                            );
                          },
                        ),
                        if (approvedUsers.isNotEmpty)
                          NeonButton(
                            label: 'Assign to Existing',
                            icon: Icons.link_rounded,
                            type: NeonButtonType.secondary,
                            onPressed: () => _showAssignPendingUserDialog(
                              context,
                              pendingUser: user,
                              approvedUsers: approvedUsers,
                            ),
                          ),
                        NeonButton(
                          label: 'Add as New',
                          icon: Icons.person_add_alt_1_rounded,
                          type: NeonButtonType.mint,
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref
                                .read(userRepositoryProvider)
                                .approveUser(user.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Added ${user.displayName} as a new member!'),
                                backgroundColor: AppColors.accentSuccess,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );

    final appointKeeperSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined,
                color: AppColors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              'APPOINT ACTIVE KEEPER',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Keeper: ${keeper?.displayName ?? "None"}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Appointing a new Keeper automatically migrates active group obligations to the newly appointed Keeper.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              for (final user in approvedUsers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: user.id == keeper?.id
                        ? null
                        : () => _confirmAppointKeeperDialog(
                            context, user, keeper, debts),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: user.id == keeper?.id
                            ? AppColors.accentPrimary.withValues(alpha: 0.12)
                            : AppColors.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: user.id == keeper?.id
                              ? AppColors.accentPrimary.withValues(alpha: 0.5)
                              : AppColors.borderDefault,
                        ),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(user: user, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (user.id == keeper?.id)
                            Text(
                              'CURRENT KEEPER',
                              style: GoogleFonts.inter(
                                color: AppColors.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            )
                          else
                            Text(
                              'Appoint',
                              style: GoogleFonts.inter(
                                color: AppColors.accentInfo,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (config != null) {
      if (_rateController.text.isEmpty) {
        _rateController.text = config.currentRatePerSwear.toStringAsFixed(0);
      }
      if (_compensationController.text.isEmpty) {
        _compensationController.text =
            config.currentCompensationPerSwear.toStringAsFixed(0);
      }
    }

    final rateSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded,
                color: AppColors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text(
              'CONSEQUENCE PENALTY RATE',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate applies to future reports. Existing reports retain their frozen captured rate.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Penalty Rate Per Swear (₱)',
                        labelStyle:
                            GoogleFonts.inter(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.bgSurfaceElevated,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeonButton(
                    label: 'Update Rate',
                    type: NeonButtonType.primary,
                    onPressed: () async {
                      final rate =
                          double.tryParse(_rateController.text.trim());
                      if (rate == null || rate <= 0) return;
                      final messenger = ScaffoldMessenger.of(context);
                      await ref
                          .read(configRepositoryProvider)
                          .updateRate(rate);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Penalty rate updated to ₱${rate.toStringAsFixed(0)}!'),
                          backgroundColor: AppColors.accentSuccess,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.card_giftcard_rounded,
                color: AppColors.accentSuccess, size: 18),
            const SizedBox(width: 8),
            Text(
              'REPORTER COMPENSATION',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Compensation',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₱${(config?.currentCompensationPerSwear ?? 0).toStringAsFixed(0)} / swear',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSuccess,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Amount members receive per swear when reporting another member. If the reporter has an existing payable, it is deducted from there first; any remainder becomes a receivable owed to them.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _compensationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Compensation Per Swear (₱)',
                        labelStyle:
                            GoogleFonts.inter(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.bgSurfaceElevated,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeonButton(
                    label: 'Update Compensation',
                    type: NeonButtonType.mint,
                    onPressed: () async {
                      final comp = double.tryParse(
                          _compensationController.text.trim());
                      final messenger = ScaffoldMessenger.of(context);
                      if (comp == null || comp < 0) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please enter a valid compensation amount (₱0 or higher).'),
                            backgroundColor: AppColors.accentError,
                          ),
                        );
                        return;
                      }
                      final currentRate = config?.currentRatePerSwear ?? 50.0;
                      if (comp > currentRate) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                'Compensation cannot exceed the penalty rate (₱${currentRate.toStringAsFixed(0)}).'),
                            backgroundColor: AppColors.accentWarning,
                          ),
                        );
                        return;
                      }
                      await ref
                          .read(configRepositoryProvider)
                          .updateCompensationRate(comp);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Reporter compensation updated to ₱${comp.toStringAsFixed(0)} per swear!'),
                          backgroundColor: AppColors.accentSuccess,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final memberManagementSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.group_outlined,
                    color: AppColors.accentInfo, size: 18),
                const SizedBox(width: 8),
                Text(
                  'MANAGE MEMBERS (${approvedUsers.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            NeonButton(
              label: 'Add Member',
              icon: Icons.person_add_alt_1_rounded,
              type: NeonButtonType.primary,
              onPressed: () => _showAddManualUserDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add people manually before they sign in, toggle Admin permissions, unlink Google accounts, or delete members.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < approvedUsers.length; i++) ...[
                Builder(
                  builder: (context) {
                    final user = approvedUsers[i];
                    final isSelf = user.id == currentUser?.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          UserAvatar(user: user, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelf) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentPrimary
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'YOU',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      user.hasLinkedAccount
                                          ? Icons.verified_user_outlined
                                          : Icons.person_outline_rounded,
                                      size: 12,
                                      color: user.hasLinkedAccount
                                          ? AppColors.accentSuccess
                                          : AppColors.accentWarning,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user.hasLinkedAccount
                                            ? (user.email.isNotEmpty
                                                ? user.email
                                                : 'Google Account Linked')
                                            : 'Manual Profile (Unlinked)',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: user.hasLinkedAccount
                                              ? AppColors.textSecondary
                                              : AppColors.accentWarning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                child: Switch(
                                  value: user.isAdmin,
                                  activeThumbColor: AppColors.accentInfo,
                                  onChanged: (val) {
                                    ref
                                        .read(userRepositoryProvider)
                                        .toggleAdminRole(user.id, val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Remove Account or Delete User',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.accentError,
                              size: 20,
                            ),
                            onPressed: () => _showRemoveOrDeleteUserDialog(
                              context,
                              targetUser: user,
                              currentUser: currentUser,
                              keeper: keeper,
                              reports: reports,
                              debts: debts,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (i < approvedUsers.length - 1)
                  const Divider(height: 1, color: AppColors.borderDefault),
              ],
            ],
          ),
        ),
      ],
    );

    final swearTemplatesSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.translate_rounded,
                color: AppColors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              'SWEAR TEMPLATES BY LANGUAGE (${swearLanguages.length})',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add languages and lists of swears inside each language to serve as templates when reporting swears.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _languageController,
                      onSubmitted: (_) => _addLanguage(swearLanguages),
                      decoration: InputDecoration(
                        labelText: 'Language Name',
                        hintText: 'e.g., English, Tagalog, Bisaya...',
                        labelStyle:
                            GoogleFonts.inter(color: AppColors.textSecondary),
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.bgSurfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NeonButton(
                    label: 'Add Language',
                    icon: Icons.add_rounded,
                    type: NeonButtonType.primary,
                    onPressed: () => _addLanguage(swearLanguages),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _initialSwearsController,
                onSubmitted: (_) => _addLanguage(swearLanguages),
                decoration: InputDecoration(
                  labelText: 'Swears inside this Language (optional)',
                  hintText: 'e.g., Fuck, Shit, Damn (comma-separated)...',
                  labelStyle:
                      GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  hintStyle:
                      GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12.5),
                  filled: true,
                  fillColor: AppColors.bgSurfaceElevated,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (swearLanguages.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Center(
                    child: Text(
                      'No languages added yet. Add a language above to create swear templates.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                for (int i = 0; i < swearLanguages.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final lang = swearLanguages[i];
                      final swearCtrl = _getSwearController(lang.id);
                      return Container(
                        margin: EdgeInsets.only(
                            bottom: i < swearLanguages.length - 1 ? 14 : 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.language_rounded,
                                  size: 16,
                                  color: AppColors.accentPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lang.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPrimary
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${lang.swears.length} swear(s)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Delete ${lang.name}',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.accentError,
                                  ),
                                  onPressed: () =>
                                      _removeLanguage(swearLanguages, lang.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (lang.swears.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  'No swears in ${lang.name} yet.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final swear in lang.swears)
                                    Container(
                                      padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 6,
                                          top: 5,
                                          bottom: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.borderDefault),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            swear,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () =>
                                                _removeSwearFromLanguage(
                                                    swearLanguages,
                                                    lang,
                                                    swear),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: swearCtrl,
                                    onSubmitted: (_) => _addSwearsToLanguage(
                                        swearLanguages, lang),
                                    onTapOutside: (_) => _addSwearsToLanguage(
                                        swearLanguages, lang),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Add swear(s) to ${lang.name} (comma-separated)...',
                                      hintStyle: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 12.5,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.bgSurface,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.borderDefault),
                                      ),
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                NeonButton(
                                  label: 'Add Swear',
                                  type: NeonButtonType.secondary,
                                  onPressed: () => _addSwearsToLanguage(
                                      swearLanguages, lang),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Console',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1120 : 600),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: isDesktop ? 24 : 12,
            ),
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          pendingApprovalsSection,
                          const SizedBox(height: 24),
                          rateSection,
                          const SizedBox(height: 24),
                          swearTemplatesSection,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          memberManagementSection,
                          const SizedBox(height: 24),
                          appointKeeperSection,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                pendingApprovalsSection,
                const SizedBox(height: 28),
                memberManagementSection,
                const SizedBox(height: 28),
                appointKeeperSection,
                const SizedBox(height: 28),
                rateSection,
                const SizedBox(height: 28),
                swearTemplatesSection,
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddManualUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final gcashController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Add Member Manually',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a person to the group now so swears can be tracked immediately. When they log in with Google later, you can assign their Google account to this profile.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Display Name *',
                  hintText: 'e.g. Marco',
                  labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
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
                    color: AppColors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gcashController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'GCash Mobile Number (Optional)',
                  hintText: 'e.g. 0917-123-4567',
                  labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
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
            label: 'Add Member',
            icon: Icons.person_add_alt_1_rounded,
            type: NeonButtonType.primary,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final gcash = gcashController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(userRepositoryProvider).createManualUser(
                    displayName: name,
                    gcashNumber: gcash.isEmpty ? null : gcash,
                  );
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Added $name to the group!'),
                  backgroundColor: AppColors.accentSuccess,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAssignPendingUserDialog(
    BuildContext context, {
    required AppUser pendingUser,
    required List<AppUser> approvedUsers,
  }) {
    // Sort unlinked manual profiles first for convenience
    final sortedTargets = List<AppUser>.from(approvedUsers)
      ..sort((a, b) {
        if (!a.hasLinkedAccount && b.hasLinkedAccount) return -1;
        if (a.hasLinkedAccount && !b.hasLinkedAccount) return 1;
        return a.displayName.compareTo(b.displayName);
      });

    String? selectedTargetId =
        sortedTargets.isNotEmpty ? sortedTargets.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.borderDefault),
            ),
            title: Text(
              'Assign Google Login to Existing User',
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
                    Text(
                      'Select which existing member profile should be linked to ${pendingUser.displayName} (${pendingUser.email.isNotEmpty ? pendingUser.email : "Google login"}):',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final target in sortedTargets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () =>
                              setModalState(() => selectedTargetId = target.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedTargetId == target.id
                                  ? AppColors.accentPrimary
                                      .withValues(alpha: 0.14)
                                  : AppColors.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedTargetId == target.id
                                    ? AppColors.accentPrimary
                                    : AppColors.borderDefault,
                              ),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(user: target, size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        target.displayName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        target.hasLinkedAccount
                                            ? 'Currently linked: ${target.email}'
                                            : 'Manual Profile (No account linked)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: target.hasLinkedAccount
                                              ? AppColors.textMuted
                                              : AppColors.accentWarning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selectedTargetId == target.id
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  size: 18,
                                  color: selectedTargetId == target.id
                                      ? AppColors.accentPrimary
                                      : AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
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
                label: 'Assign Account',
                icon: Icons.link_rounded,
                type: NeonButtonType.primary,
                onPressed: selectedTargetId == null
                    ? null
                    : () async {
                        final target = sortedTargets
                            .firstWhere((u) => u.id == selectedTargetId);
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await ref
                            .read(userRepositoryProvider)
                            .assignPendingUserToExisting(
                              pendingUserId: pendingUser.id,
                              targetUserId: target.id,
                            );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                'Linked ${pendingUser.email.isNotEmpty ? pendingUser.email : pendingUser.displayName} to ${target.displayName}!'),
                            backgroundColor: AppColors.accentSuccess,
                          ),
                        );
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemoveOrDeleteUserDialog(
    BuildContext context, {
    required AppUser targetUser,
    required AppUser? currentUser,
    required AppUser? keeper,
    required List<SwearReport> reports,
    required List<DebtObligation> debts,
  }) {
    final isSelf = targetUser.id == currentUser?.id;
    final isTargetKeeper = targetUser.id == keeper?.id;
    final canDeleteCompletely = !isSelf && !isTargetKeeper;
    final accusedReportCount =
        reports.where((r) => r.accusedId == targetUser.id).length;
    final debtorDebtCount =
        debts.where((d) => d.debtorId == targetUser.id).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Manage ${targetUser.displayName}',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose how you want to remove or reset ${targetUser.displayName}:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                // Option 1: Remove Linked Google Account using the User Profile
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: targetUser.hasLinkedAccount
                          ? AppColors.accentWarning.withValues(alpha: 0.4)
                          : AppColors.borderDefault,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link_off_rounded,
                              size: 18, color: AppColors.accentWarning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Option 1: Remove Linked Account Only',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        targetUser.hasLinkedAccount
                            ? 'Unlinks the Google account (${targetUser.email.isNotEmpty ? targetUser.email : "linked login"}) from this profile. ${targetUser.displayName} remains in the group with all swear & debt history intact.'
                            : 'This profile does not currently have a Google account linked.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'Remove Account from Profile',
                        icon: Icons.link_off_rounded,
                        type: NeonButtonType.secondary,
                        width: double.infinity,
                        onPressed: !targetUser.hasLinkedAccount
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);
                                await ref
                                    .read(userRepositoryProvider)
                                    .unlinkUserAccount(targetUser.id);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Removed Google account from ${targetUser.displayName}. Profile and history kept.'),
                                    backgroundColor: AppColors.accentInfo,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Option 2: Delete User Completely & Wipe History
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentError.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentError.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.delete_forever_rounded,
                              size: 18, color: AppColors.accentError),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Option 2: Delete User & All History',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.accentError,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Permanently deletes ${targetUser.displayName} along with $accusedReportCount swear report(s) and $debtorDebtCount debt record(s) belonging to them. Reports they filed against others will be kept.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isTargetKeeper) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Cannot delete the active Keeper. Please appoint a different Keeper first.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentWarning,
                          ),
                        ),
                      ] else if (isSelf) ...[
                        const SizedBox(height: 8),
                        Text(
                          'You cannot delete your own active Admin profile while signed in.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentWarning,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'Delete User & History',
                        icon: Icons.delete_forever_rounded,
                        type: NeonButtonType.danger,
                        width: double.infinity,
                        onPressed: !canDeleteCompletely
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);
                                await ref
                                    .read(userRepositoryProvider)
                                    .deleteUserCompletely(
                                      userId: targetUser.id,
                                      existingReports: reports,
                                      existingDebts: debts,
                                    );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Deleted ${targetUser.displayName} and all their swear/debt history.'),
                                    backgroundColor: AppColors.accentError,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _confirmAppointKeeperDialog(
    BuildContext context,
    AppUser newKeeper,
    AppUser? oldKeeper,
    List<DebtObligation> debts,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        title: Text(
          'Appoint ${newKeeper.displayName} as Keeper?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            'This will transfer Keeper responsibilities and migrate active standard group debts to ${newKeeper.displayName}.',
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
            label: 'Appoint Keeper',
            type: NeonButtonType.primary,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(userRepositoryProvider).appointKeeper(
                    newKeeper.id,
                    oldKeeper?.id ?? '',
                    debts,
                  );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      '${newKeeper.displayName} is now the active Keeper!'),
                  backgroundColor: AppColors.accentSuccess,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

