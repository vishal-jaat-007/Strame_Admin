import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../common/glass_card.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Container(
        padding: app_utils.AppResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 18,
                      ),
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: AdminTheme.spacingSm),

                TextButton(
                  onPressed: () {
                    // TODO: Show all activities
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          app_utils.AppResponsiveUtils.isMobile(context)
                              ? 8
                              : 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    app_utils.AppResponsiveUtils.isMobile(context)
                        ? 'All'
                        : 'View All',
                    style: TextStyle(
                      fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 13,
                      ),
                      color: AdminTheme.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingLg),

            // Activities list
            ...List.generate(8, (index) => _buildActivityItem(context, index)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, int index) {
    final activities = [
      {
        'icon': Icons.person_add,
        'title': 'New user registered',
        'subtitle': 'John Doe joined the platform',
        'time': '2 minutes ago',
        'color': AdminTheme.electricBlue,
      },
      {
        'icon': Icons.star,
        'title': 'Creator approved',
        'subtitle': 'Sarah Smith became a creator',
        'time': '5 minutes ago',
        'color': AdminTheme.successGreen,
      },
      {
        'icon': Icons.call_end,
        'title': 'Call completed',
        'subtitle': 'Voice call lasted 15 minutes',
        'time': '8 minutes ago',
        'color': AdminTheme.warningOrange,
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Withdrawal processed',
        'subtitle': '₹2,500 paid to creator',
        'time': '12 minutes ago',
        'color': AdminTheme.primaryPurple,
      },
      {
        'icon': Icons.live_tv,
        'title': 'Live session ended',
        'subtitle': 'Creator had 45 viewers',
        'time': '18 minutes ago',
        'color': AdminTheme.errorRed,
      },
      {
        'icon': Icons.block,
        'title': 'User blocked',
        'subtitle': 'Violation of community guidelines',
        'time': '25 minutes ago',
        'color': AdminTheme.errorRed,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Revenue milestone',
        'subtitle': 'Daily earnings crossed ₹10,000',
        'time': '1 hour ago',
        'color': AdminTheme.successGreen,
      },
      {
        'icon': Icons.notification_important,
        'title': 'System alert',
        'subtitle': 'Server maintenance scheduled',
        'time': '2 hours ago',
        'color': AdminTheme.warningOrange,
      },
    ];

    final activity = activities[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingMd),
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminTheme.cardDarker.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.borderColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),

          const SizedBox(width: AdminTheme.spacingMd),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity['title'] as String,
                  style: TextStyle(
                    fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
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
                  activity['subtitle'] as String,
                  style: TextStyle(
                    fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
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

          const SizedBox(width: AdminTheme.spacingSm),

          // Time
          Flexible(
            child: Text(
              activity['time'] as String,
              style: AdminTheme.labelSmall.copyWith(
                color: AdminTheme.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

