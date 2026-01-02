import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../../models/navigation_item.dart';
import '../common/glass_card.dart';
import '../common/animated_button.dart';

class QuickActions extends StatefulWidget {
  final ValueChanged<NavigationItem> onNavItemChanged;

  const QuickActions({super.key, required this.onNavItemChanged});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _pendingApprovals = 0;
  int _pendingWithdrawals = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners();
    });
  }

  void _setupListeners() {
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    final currentUid = authProvider.currentAdmin?.uid;

    debugPrint(
      '🔐 [QuickActions] Setting up listeners. Current Admin UID: $currentUid',
    );

    // Listen for pending creator approvals
    _firestore
        .collection('creators')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() => _pendingApprovals = snapshot.docs.length);
              debugPrint(
                '📊 [QuickActions] Pending Approvals: $_pendingApprovals',
              );
            }
          },
          onError: (e) {
            debugPrint('❌ [QuickActions] Error fetching pending approvals: $e');
          },
        );

    // Listen for pending withdrawals
    _firestore
        .collection('withdraw_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() => _pendingWithdrawals = snapshot.docs.length);
              debugPrint(
                '📊 [QuickActions] Pending Withdrawals: $_pendingWithdrawals',
              );
            }
          },
          onError: (e) {
            debugPrint(
              '❌ [QuickActions] Error fetching pending withdrawals: $e',
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Container(
        padding: app_utils.AppResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            _buildActionButton(
              context,
              icon: Icons.approval,
              title: 'Pending Approvals',
              subtitle: '$_pendingApprovals creator requests waiting',
              color: AdminTheme.warningOrange,
              onPressed:
                  () => widget.onNavItemChanged(NavigationItem.creatorApproval),
              hasNotification: _pendingApprovals > 0,
            ),

            _buildActionButton(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Process Withdrawals',
              subtitle: '$_pendingWithdrawals withdrawal requests',
              color: AdminTheme.successGreen,
              onPressed:
                  () => widget.onNavItemChanged(NavigationItem.withdrawals),
              hasNotification: _pendingWithdrawals > 0,
            ),

            _buildActionButton(
              context,
              icon: Icons.notifications,
              title: 'Send Notification',
              subtitle: 'Broadcast to all users',
              color: AdminTheme.electricBlue,
              onPressed:
                  () => widget.onNavItemChanged(NavigationItem.notifications),
            ),

            _buildActionButton(
              context,
              icon: Icons.analytics,
              title: 'Generate Report',
              subtitle: 'Export analytics data',
              color: AdminTheme.neonMagenta,
              onPressed: () => widget.onNavItemChanged(NavigationItem.reports),
            ),

            _buildActionButton(
              context,
              icon: Icons.settings,
              title: 'System Settings',
              subtitle: 'Configure app settings',
              color: AdminTheme.textSecondary,
              onPressed: () => widget.onNavItemChanged(NavigationItem.settings),
            ),

            const SizedBox(height: AdminTheme.spacingLg),

            _buildEmergencyActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyActions(BuildContext context) {
    return Container(
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
              Icon(Icons.warning_rounded, color: AdminTheme.errorRed, size: 20),
              const SizedBox(width: AdminTheme.spacingSm),
              Text(
                'Emergency Actions',
                style: AdminTheme.bodyMedium.copyWith(
                  color: AdminTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed:
                  () => _showEmergencyDialog(context, 'Maintenance Mode'),
              backgroundColor: AdminTheme.errorRed,
              child: Text(
                'Enable Maintenance',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AdminTheme.errorRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AdminTheme.backgroundPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AdminTheme.spacingLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AdminTheme.textSecondary),
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
            title: Text(
              'Confirm $action',
              style: const TextStyle(color: AdminTheme.errorRed),
            ),
            content: Text('Are you sure? This will affect all live users.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: AdminTheme.errorRed),
                ),
              ),
            ],
          ),
    );
  }
}
