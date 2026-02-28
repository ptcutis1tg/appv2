import 'package:flutter/material.dart';
import 'package:appv2/data/mock_data.dart';
import 'package:appv2/widgets/shared/bottom_nav_bar.dart';
import 'package:appv2/widgets/shared/settings_list_tile.dart';
import 'package:appv2/db/user_repository.dart';

/// Settings screen: profile, data & security, app settings, logout.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _cloudSync = true;
  final _userRepo = UserRepository();
  UserProfileData? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userRepo.getUser();
    if (mounted) {
      setState(() {
        _userProfile = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _AppBar(
                    theme: theme,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _ProfileCard(
                            colors: colors,
                            theme: theme,
                            user: _userProfile,
                          ),
                          const Divider(height: 1),
                          _SettingsSections(
                            colors: colors,
                            theme: theme,
                            cloudSync: _cloudSync,
                            onCloudSyncChanged: (v) =>
                                setState(() => _cloudSync = v),
                          ),
                          _LogoutButton(colors: colors),
                          _VersionInfo(colors: colors, theme: theme),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (i) {
          if (i != 3) Navigator.of(context).pop();
        },
        items: const [
          BottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Thu chi',
          ),
          BottomNavItem(icon: Icons.analytics_outlined, label: 'Thống kê'),
          BottomNavItem(icon: Icons.savings_outlined, label: 'Ngân sách'),
          BottomNavItem(icon: Icons.settings, label: 'Cài đặt'),
        ],
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({required this.theme, required this.onBack});

  final ThemeData theme;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
              child: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: Text(
              'Cài đặt',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 40), // balance the back button
        ],
      ),
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.colors,
    required this.theme,
    required this.user,
  });

  final ColorScheme colors;
  final ThemeData theme;
  final UserProfileData? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: user == null
                    ? CircleAvatar(
                        radius: 48,
                        backgroundColor: colors.primary.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: colors.primary,
                        ),
                      )
                    : ClipOval(
                        child: Image.network(
                          user!.avatarUrl,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 48,
                            backgroundColor: colors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.edit, size: 16, color: colors.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'No profile', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'No email',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (user?.badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                user!.badge!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Settings Sections ────────────────────────────────────────────────
class _SettingsSections extends StatelessWidget {
  const _SettingsSections({
    required this.colors,
    required this.theme,
    required this.cloudSync,
    required this.onCloudSyncChanged,
  });

  final ColorScheme colors;
  final ThemeData theme;
  final bool cloudSync;
  final ValueChanged<bool> onCloudSyncChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            label: 'Dữ liệu & Bảo mật',
            theme: theme,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SettingsListTile(
                  icon: Icons.cloud_sync,
                  title: 'Đồng bộ Cloud',
                  trailing: Switch(
                    value: cloudSync,
                    onChanged: onCloudSyncChanged,
                    activeColor: colors.primary,
                  ),
                ),
                SettingsListTile(
                  icon: Icons.file_upload_outlined,
                  title: 'Xuất dữ liệu (CSV/Excel)',
                ),
                SettingsListTile(
                  icon: Icons.fingerprint,
                  title: 'FaceID / Mã PIN',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Ứng dụng', theme: theme, colors: colors),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SettingsListTile(
                  icon: Icons.payments,
                  title: 'Đơn vị tiền tệ',
                  subtitle: 'VND (₫)',
                ),
                SettingsListTile(
                  icon: Icons.dark_mode,
                  title: 'Chế độ tối',
                  subtitle: 'Bật',
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.theme,
    required this.colors,
  });

  final String label;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Logout Button ────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error.withValues(alpha: 0.1),
            foregroundColor: colors.error,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Version Info ─────────────────────────────────────────────────────
class _VersionInfo extends StatelessWidget {
  const _VersionInfo({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Smart Finance v2.4.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BUILD 20240501',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
