import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../theme/admin_theme.dart';
import '../../models/navigation_item.dart';
import '../../screens/modules/dashboard/dashboard_module.dart';
import '../../screens/modules/users/users_module.dart';
import '../../screens/modules/creators/creators_module.dart';
import '../../screens/modules/creator_approval/creator_approval_module.dart';
import '../../screens/modules/calls/calls_module.dart';
import '../../screens/modules/live/live_module.dart';
import '../../screens/modules/withdrawals/withdrawals_module.dart';
import '../../screens/modules/transactions/transactions_module.dart';
import '../../screens/modules/notifications/notifications_module.dart';
import '../../screens/modules/content/content_module.dart';

class AdminContent extends StatelessWidget {
  final NavigationItem selectedItem;

  const AdminContent({
    super.key,
    required this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? AdminTheme.spacingMd : AdminTheme.spacingLg),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (selectedItem) {
      case NavigationItem.dashboard:
        return const DashboardModule();
      case NavigationItem.users:
        return const UsersModule();
      case NavigationItem.creators:
        return const CreatorsModule();
      case NavigationItem.creatorApproval:
        return const CreatorApprovalModule();
      case NavigationItem.calls:
        return const CallsModule();
      case NavigationItem.live:
        return const LiveModule();
      case NavigationItem.withdrawals:
        return const WithdrawalsModule();
      case NavigationItem.transactions:
        return const TransactionsModule();
      case NavigationItem.notifications:
        return const NotificationsModule();
      case NavigationItem.content:
        return const ContentModule();
      case NavigationItem.settings:
        return _buildPlaceholder('Settings', 'App configuration and preferences');
    }
  }

  Widget _buildPlaceholder(String title, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AdminTheme.cardDark,
              borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
              border: Border.all(
                color: AdminTheme.borderColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              selectedItem.icon,
              size: 60,
              color: selectedItem.color,
            ),
          ),
          
          const SizedBox(height: AdminTheme.spacingXl),
          
          Text(
            title,
            style: AdminTheme.headlineLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AdminTheme.spacingSm),
          
          Text(
            description,
            style: AdminTheme.bodyLarge.copyWith(
              color: AdminTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AdminTheme.spacingXl),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.spacingLg,
              vertical: AdminTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: selectedItem.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(
                color: selectedItem.color.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Coming Soon',
              style: AdminTheme.bodyMedium.copyWith(
                color: selectedItem.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
























