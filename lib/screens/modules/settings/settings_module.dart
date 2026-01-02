import 'package:flutter/material.dart';
import '../../../theme/admin_theme.dart';
import '../../../widgets/common/glass_card.dart';
import '../../../services/app_config_service.dart';
import '../../../widgets/settings/admin_management_section.dart';

class SettingsModule extends StatefulWidget {
  const SettingsModule({super.key});

  @override
  State<SettingsModule> createState() => _SettingsModuleState();
}

class _SettingsModuleState extends State<SettingsModule> {
  final AppConfigService _configService = AppConfigService();
  bool _showingAdminManagement = false;

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _configService.updateSystemSettings({key: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting updated: $key'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            _showingAdminManagement
                ? AdminManagementSection(
                  onBack: () => setState(() => _showingAdminManagement = false),
                )
                : _buildMainSettings(),
      ),
    );
  }

  Widget _buildMainSettings() {
    return StreamBuilder<Map<String, dynamic>>(
      key: const ValueKey('main_settings'),
      stream: _configService.getSystemSettings(),
      builder: (context, snapshot) {
        final settings =
            snapshot.data ??
            {'maintenanceMode': false, 'registrationsOpen': true};
        final bool maintenanceMode = settings['maintenanceMode'] ?? false;
        final bool registrationsOpen = settings['registrationsOpen'] ?? true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Settings', style: AdminTheme.headlineMedium),
            const SizedBox(height: AdminTheme.spacingXs),
            Text(
              'Configure global app behaviors and parameters.',
              style: AdminTheme.bodyMedium.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),

            const SizedBox(height: AdminTheme.spacingXl),

            _buildSection(
              title: 'System Control',
              children: [
                _buildSwitchTile(
                  title: 'Maintenance Mode',
                  subtitle: 'Disables app access for all users except admins.',
                  value: maintenanceMode,
                  onChanged: (v) => _updateSetting('maintenanceMode', v),
                  icon: Icons.construction_rounded,
                  color: AdminTheme.warningOrange,
                ),
                const Divider(color: AdminTheme.borderColor),
                _buildSwitchTile(
                  title: 'New Registrations',
                  subtitle: 'Allow new users to create accounts.',
                  value: registrationsOpen,
                  onChanged: (v) => _updateSetting('registrationsOpen', v),
                  icon: Icons.person_add_rounded,
                  color: AdminTheme.successGreen,
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingLg),

            _buildSection(
              title: 'Security',
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AdminTheme.primaryPurple,
                  ),
                  title: const Text(
                    'Manage Admin Accounts',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Add or remove administrator access.',
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AdminTheme.textSecondary,
                  ),
                  onTap: () {
                    setState(() => _showingAdminManagement = true);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AdminTheme.labelSmall.copyWith(
              color: AdminTheme.textTertiary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GlassCard(padding: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
      ),
      activeColor: color,
    );
  }
}
