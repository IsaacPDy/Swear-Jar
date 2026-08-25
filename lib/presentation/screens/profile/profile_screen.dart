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

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              NeonCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    UserAvatar(user: currentUser, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      currentUser.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final role in currentUser.roles)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: role == UserRole.keeper
                                  ? AppColors.accentPrimary.withValues(alpha: 0.18)
                                  : (role == UserRole.admin
                                      ? AppColors.accentInfo.withValues(alpha: 0.18)
                                      : AppColors.bgSurfaceElevated),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: role == UserRole.keeper
                                    ? AppColors.accentPrimary.withValues(alpha: 0.5)
                                    : (role == UserRole.admin
                                        ? AppColors.accentInfo.withValues(alpha: 0.5)
                                        : AppColors.borderDefault),
                              ),
                            ),
                            child: Text(
                              role.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: role == UserRole.keeper
                                    ? AppColors.accentPrimary
                                    : (role == UserRole.admin ? AppColors.accentInfo : AppColors.textSecondary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NeonCard(
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
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
                          child: Text(
                            _isEditing ? 'Save Changes' : 'Edit',
                            style: GoogleFonts.inter(
                              color: AppColors.accentPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing) ...[
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 20, color: AppColors.accentInfo),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GCash Number',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                              ),
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
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (currentUser.isAdmin) ...[
                const SizedBox(height: 16),
                NeonCard(
                  backgroundColor: AppColors.accentInfo.withValues(alpha: 0.1),
                  borderColor: AppColors.accentInfo.withValues(alpha: 0.4),
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
                          color: AppColors.accentInfo.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: AppColors.accentInfo, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Manage user approvals, appoint Keeper, update penalty rate.',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              NeonButton(
                label: 'Sign Out',
                icon: Icons.logout,
                type: NeonButtonType.danger,
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
              const SizedBox(height: 24),
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
