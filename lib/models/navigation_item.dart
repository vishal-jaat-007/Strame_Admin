import 'package:flutter/material.dart';

enum NavigationItem {
  dashboard,
  users,
  creators,
  creatorApproval,
  calls,
  live,
  withdrawals,
  transactions,
  notifications,
  content,
  monetization,
  reports,
  settings,
}

extension NavigationItemExtension on NavigationItem {
  String get title {
    switch (this) {
      case NavigationItem.dashboard:
        return 'Dashboard';
      case NavigationItem.users:
        return 'User Management';
      case NavigationItem.creators:
        return 'Creator Management';
      case NavigationItem.creatorApproval:
        return 'Creator Approval';
      case NavigationItem.calls:
        return 'Call Monitoring';
      case NavigationItem.live:
        return 'Live Monitoring';
      case NavigationItem.withdrawals:
        return 'Withdraw Requests';
      case NavigationItem.transactions:
        return 'Transactions';
      case NavigationItem.notifications:
        return 'Notifications';
      case NavigationItem.content:
        return 'Content & Banners';
      case NavigationItem.monetization:
        return 'Coins & Earnings';
      case NavigationItem.reports:
        return 'Analytics Reports';
      case NavigationItem.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationItem.dashboard:
        return Icons.dashboard_rounded;
      case NavigationItem.users:
        return Icons.people_rounded;
      case NavigationItem.creators:
        return Icons.star_rounded;
      case NavigationItem.creatorApproval:
        return Icons.approval_rounded;
      case NavigationItem.calls:
        return Icons.call_rounded;
      case NavigationItem.live:
        return Icons.live_tv_rounded;
      case NavigationItem.withdrawals:
        return Icons.account_balance_wallet_rounded;
      case NavigationItem.transactions:
        return Icons.receipt_long_rounded;
      case NavigationItem.notifications:
        return Icons.notifications_rounded;
      case NavigationItem.content:
        return Icons.image_rounded;
      case NavigationItem.monetization:
        return Icons.monetization_on_rounded;
      case NavigationItem.reports:
        return Icons.bar_chart_rounded;
      case NavigationItem.settings:
        return Icons.settings_rounded;
    }
  }

  String get route {
    switch (this) {
      case NavigationItem.dashboard:
        return '/dashboard';
      case NavigationItem.users:
        return '/users';
      case NavigationItem.creators:
        return '/creators';
      case NavigationItem.creatorApproval:
        return '/creator-approval';
      case NavigationItem.calls:
        return '/calls';
      case NavigationItem.live:
        return '/live';
      case NavigationItem.withdrawals:
        return '/withdrawals';
      case NavigationItem.transactions:
        return '/transactions';
      case NavigationItem.notifications:
        return '/notifications';
      case NavigationItem.content:
        return '/content';
      case NavigationItem.monetization:
        return '/monetization';
      case NavigationItem.reports:
        return '/reports';
      case NavigationItem.settings:
        return '/settings';
    }
  }

  Color get color {
    switch (this) {
      case NavigationItem.dashboard:
        return const Color(0xFF6A4CFF);
      case NavigationItem.users:
        return const Color(0xFF00D4FF);
      case NavigationItem.creators:
        return const Color(0xFFFFD700);
      case NavigationItem.creatorApproval:
        return const Color(0xFFFF9500);
      case NavigationItem.calls:
        return const Color(0xFF00FF87);
      case NavigationItem.live:
        return const Color(0xFFFF00E5);
      case NavigationItem.withdrawals:
        return const Color(0xFF5A9CFF);
      case NavigationItem.transactions:
        return const Color(0xFF00FF87);
      case NavigationItem.notifications:
        return const Color(0xFFFF9500);
      case NavigationItem.content:
        return const Color(0xFFFF00E5);
      case NavigationItem.monetization:
        return const Color(0xFFFFD700);
      case NavigationItem.reports:
        return const Color(0xFF00D4FF);
      case NavigationItem.settings:
        return const Color(0xFFB0B0B0);
    }
  }

  bool get hasNotification {
    switch (this) {
      case NavigationItem.creatorApproval:
      case NavigationItem.withdrawals:
      case NavigationItem.notifications:
        return true;
      default:
        return false;
    }
  }

  String get description {
    switch (this) {
      case NavigationItem.dashboard:
        return 'Overview and analytics';
      case NavigationItem.users:
        return 'Manage app users';
      case NavigationItem.creators:
        return 'Manage creators';
      case NavigationItem.creatorApproval:
        return 'Approve creator requests';
      case NavigationItem.calls:
        return 'Monitor voice/video calls';
      case NavigationItem.live:
        return 'Monitor live sessions';
      case NavigationItem.withdrawals:
        return 'Process withdrawal requests';
      case NavigationItem.transactions:
        return 'View all transactions';
      case NavigationItem.notifications:
        return 'Send notifications';
      case NavigationItem.content:
        return 'Manage banners & content';
      case NavigationItem.monetization:
        return 'Manage call rates and coin pricing';
      case NavigationItem.reports:
        return 'Export and view analytics reports';
      case NavigationItem.settings:
        return 'App settings';
    }
  }
}
