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

  @override
  void initState() {
    super.initState();
    final config = ref.read(systemConfigProvider).valueOrNull;
    if (config != null) {
      _rateController.text = config.currentRatePerSwear.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingUsers = ref.watch(pendingUsersProvider);
    final approvedUsers = ref.watch(approvedUsersProvider);
    final keeper = ref.watch(activeKeeperProvider);
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
              'PENDING USER APPROVALS (${pendingUsers.length})',
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
                'No pending user registrations.',
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
                child: Row(
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
                    NeonButton(
                      label: 'Reject',
                      type: NeonButtonType.danger,
                      onPressed: () => ref
                          .read(userRepositoryProvider)
                          .rejectUser(user.id),
                    ),
                    const SizedBox(width: 8),
                    NeonButton(
                      label: 'Approve',
                      type: NeonButtonType.mint,
                      onPressed: () => ref
                          .read(userRepositoryProvider)
                          .approveUser(user.id),
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
      ],
    );

    final adminPermissionsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEMBER ADMIN PERMISSIONS',
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
          child: Column(
            children: [
              for (final user in approvedUsers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      UserAvatar(user: user, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: user.isAdmin,
                        activeThumbColor: AppColors.accentInfo,
                        onChanged: (val) {
                          ref
                              .read(userRepositoryProvider)
                              .toggleAdminRole(user.id, val);
                        },
                      ),
                    ],
                  ),
                ),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          appointKeeperSection,
                          const SizedBox(height: 24),
                          adminPermissionsSection,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                pendingApprovalsSection,
                const SizedBox(height: 28),
                appointKeeperSection,
                const SizedBox(height: 28),
                rateSection,
                const SizedBox(height: 28),
                adminPermissionsSection,
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
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

