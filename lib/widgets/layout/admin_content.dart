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
import '../../screens/modules/monetization/monetization_module.dart';
import '../../screens/modules/reports/reports_module.dart';
import '../../screens/modules/settings/settings_module.dart';

class AdminContent extends StatelessWidget {
  final NavigationItem selectedItem;
  final ValueChanged<NavigationItem> onNavItemChanged;

  const AdminContent({
    super.key,
    required this.selectedItem,
    required this.onNavItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      padding: EdgeInsets.all(
        isMobile ? AdminTheme.spacingMd : AdminTheme.spacingLg,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (selectedItem) {
      case NavigationItem.dashboard:
        return DashboardModule(onNavItemChanged: onNavItemChanged);
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
      case NavigationItem.monetization:
        return const MonetizationModule();
      case NavigationItem.reports:
        return const ReportsModule();
      case NavigationItem.settings:
        return const SettingsModule();
    }
  }
}


