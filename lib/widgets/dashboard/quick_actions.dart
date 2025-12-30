import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../common/glass_card.dart';
import '../common/animated_button.dart';

import '../../screens/admin/add_admin_screen.dart';

import '../../screens/admin/pending_approvals_screen.dart';
import '../../screens/admin/withdrawal_requests_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Container(
        padding: app_utils.AppResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 18,
                ),
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),

            const SizedBox(height: AdminTheme.spacingLg),

            // Action buttons
            _buildActionButton(
              context,
              icon: Icons.person_add,
              title: 'Add Admin',
              subtitle: 'Create new admin account',
              color: AdminTheme.primaryPurple,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAdminScreen(),
                  ),
                );
              },
            ),

            _buildActionButton(
              context,
              icon: Icons.approval,
              title: 'Pending Approvals',
              subtitle: '3 creator requests waiting',
              color: AdminTheme.warningOrange,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PendingApprovalsScreen(),
                  ),
                );
              },
              hasNotification: true,
            ),

            _buildActionButton(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Process Withdrawals',
              subtitle: '5 withdrawal requests',
              color: AdminTheme.successGreen,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WithdrawalRequestsScreen(),
                  ),
                );
              },
              hasNotification: true,
            ),

            _buildActionButton(
              context,
              icon: Icons.notifications,
              title: 'Send Notification',
              subtitle: 'Broadcast to all users',
              color: AdminTheme.electricBlue,
              onPressed: () {
                // TODO: Show notification dialog
              },
            ),

            _buildActionButton(
              context,
              icon: Icons.analytics,
              title: 'Generate Report',
              subtitle: 'Export analytics data',
              color: AdminTheme.neonMagenta,
              onPressed: () {
                // TODO: Generate report
              },
            ),

            _buildActionButton(
              context,
              icon: Icons.settings,
              title: 'System Settings',
              subtitle: 'Configure app settings',
              color: AdminTheme.textSecondary,
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),

            const SizedBox(height: AdminTheme.spacingLg),

            // Emergency actions
            Container(
              padding: const EdgeInsets.all(AdminTheme.spacingMd),
              decoration: BoxDecoration(
                color: AdminTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                border: Border.all(color: AdminTheme.errorRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: AdminTheme.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: AdminTheme.spacingSm),
                      Flexible(
                        child: Text(
                          app_utils.AppResponsiveUtils.isMobile(context)
                              ? 'Emergency'
                              : 'Emergency Actions',
                          style: AdminTheme.bodyMedium.copyWith(
                            color: AdminTheme.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AdminTheme.spacingMd),

                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      onPressed: () {
                        _showEmergencyDialog(context, 'Maintenance Mode');
                      },
                      backgroundColor: AdminTheme.errorRed,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.build,
                            size:
                                app_utils.AppResponsiveUtils.isMobile(context)
                                    ? 12
                                    : 16,
                          ),
                          SizedBox(
                            width:
                                app_utils.AppResponsiveUtils.isMobile(context)
                                    ? 2
                                    : AdminTheme.spacingSm,
                          ),
                          Flexible(
                            child: Text(
                              app_utils.AppResponsiveUtils.isMobile(context)
                                  ? 'Maintenance'
                                  : 'Enable Maintenance',
                              style: TextStyle(
                                fontSize: app_utils
                                    .AppResponsiveUtils.responsiveFontSize(
                                  context,
                                  mobile: 10,
                                  tablet: 12.0,
                                  desktop: 14.0,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingMd),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(AdminTheme.spacingMd),
            decoration: BoxDecoration(
              color: AdminTheme.cardDarker.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                // Icon
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),

                    if (hasNotification)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AdminTheme.errorRed,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AdminTheme.backgroundPrimary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '!',
                              style: AdminTheme.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(
                  width:
                      app_utils.AppResponsiveUtils.responsiveSpacing(context) *
                      0.5,
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: app_utils
                              .AppResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                          ),
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: app_utils
                              .AppResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 12,
                          ),
                          color: AdminTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: AdminTheme.textSecondary,
                  size: app_utils.AppResponsiveUtils.responsive(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_rounded, color: AdminTheme.errorRed),
                const SizedBox(width: AdminTheme.spacingSm),
                Text(
                  'Emergency Action',
                  style: AdminTheme.headlineSmall.copyWith(
                    color: AdminTheme.errorRed,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to enable $action? This will affect all users.',
              style: AdminTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AdminTheme.bodyMedium.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ),
              AnimatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement emergency action
                },
                backgroundColor: AdminTheme.errorRed,
                child: Text(
                  'Confirm',
                  style: AdminTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
