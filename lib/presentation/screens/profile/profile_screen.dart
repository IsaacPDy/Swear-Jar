import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/presentation/providers/providers.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/presentation/widgets/common_widgets.dart';
import 'package:swear_jar/presentation/screens/admin/admin_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _gcashController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _nameController.text = user.displayName;
      _gcashController.text = user.gcashNumber ?? '';
    }
  }

  @override
  void dispose() {
    _gcashController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final users = ref.watch(usersListProvider).valueOrNull ?? [];
    final isDesktop = AppBreakpoints.isDesktop(context);

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final identityCard = NeonCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          UserAvatar(user: currentUser, size: 64),
          const SizedBox(height: 12),
          Text(
            currentUser.displayName,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser.email,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final role in currentUser.roles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == UserRole.keeper
                        ? AppColors.accentPrimary.withValues(alpha: 0.14)
                        : (role == UserRole.admin
                            ? AppColors.accentInfo.withValues(alpha: 0.14)
                            : AppColors.bgSurfaceElevated),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: role == UserRole.keeper
                          ? AppColors.accentPrimary.withValues(alpha: 0.4)
                          : (role == UserRole.admin
                              ? AppColors.accentInfo.withValues(alpha: 0.4)
                              : AppColors.borderDefault),
                    ),
                  ),
                  child: Text(
                    role.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: role == UserRole.keeper
                          ? AppColors.accentPrimary
                          : (role == UserRole.admin
                              ? AppColors.accentInfo
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final paymentDetailsCard = NeonCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_isEditing) {
                    _saveProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Edit',
                  style: GoogleFonts.inter(
                    color: AppColors.accentPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgSurfaceElevated,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gcashController,
              decoration: InputDecoration(
                labelText: 'GCash Mobile Number',
                hintText: 'e.g. 0917-123-4567',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgSurfaceElevated,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentInfo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone_android_outlined,
                    size: 18,
                    color: AppColors.accentInfo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GCash Number',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentUser.gcashNumber?.isNotEmpty == true
                            ? currentUser.gcashNumber!
                            : 'Not set (tap Edit to add)',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    final adminCard = currentUser.isAdmin
        ? NeonCard(
            backgroundColor: AppColors.accentInfo.withValues(alpha: 0.08),
            borderColor: AppColors.accentInfo.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentInfo.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.accentInfo,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage user approvals, appoint Keeper, update penalty rate.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          )
        : null;

    final signOutButton = NeonButton(
      label: 'Sign Out',
      icon: Icons.logout_rounded,
      type: NeonButtonType.danger,
      width: double.infinity,
      onPressed: () => ref.read(authRepositoryProvider).signOut(),
    );

    final groupMembersSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GROUP MEMBERS',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        NeonCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (int i = 0; i < users.length; i++) ...[
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: UserAvatar(user: users[i], size: 38),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          users[i].displayName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: users[i].id == currentUser.id
                                ? AppColors.accentPrimary
                                : AppColors.textPrimary,
                            fontWeight: users[i].id == currentUser.id
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (users[i].id == currentUser.id) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    users[i].roles.map((r) => r.name.toUpperCase()).join(' • '),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: users[i].isKeeper
                          ? AppColors.accentPrimary
                          : AppColors.textMuted,
                      fontWeight:
                          users[i].isKeeper ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: users[i].isKeeper
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accentPrimary
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 12,
                                color: AppColors.accentPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Keeper',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (users[i].isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentInfo
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accentInfo
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                'Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentInfo,
                                ),
                              ),
                            )
                          : null),
                ),
                if (i < users.length - 1)
                  const Divider(height: 1, color: AppColors.borderDefault),
              ],
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Profile',
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
                          identityCard,
                          const SizedBox(height: 16),
                          paymentDetailsCard,
                          if (adminCard != null) ...[
                            const SizedBox(height: 16),
                            adminCard,
                          ],
                          const SizedBox(height: 20),
                          signOutButton,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: groupMembersSection,
                    ),
                  ],
                )
              else ...[
                identityCard,
                const SizedBox(height: 20),
                paymentDetailsCard,
                if (adminCard != null) ...[
                  const SizedBox(height: 16),
                  adminCard,
                ],
                const SizedBox(height: 24),
                groupMembersSection,
                const SizedBox(height: 24),
                signOutButton,
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final gcash = _gcashController.text.trim();

    await ref.read(authRepositoryProvider).updateProfile(
          displayName: name.isEmpty ? null : name,
          gcashNumber: gcash.isEmpty ? null : gcash,
        );

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.accentSuccess,
        ),
      );
    }
  }
}

