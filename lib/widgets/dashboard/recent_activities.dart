import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../common/glass_card.dart';
import '../../services/recent_activity_service.dart';
import '../../screens/dashboard/all_activities_screen.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final activityService = RecentActivityService();

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllActivitiesScreen(),
                      ),
                    );
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
            StreamBuilder<List<ActivityItem>>(
              stream: activityService.getActivitiesStream(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading activities',
                      style: TextStyle(color: AdminTheme.errorRed),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AdminTheme.primaryPurple,
                      ),
                    ),
                  );
                }

                final activities = snapshot.data!;

                if (activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No recent activities',
                        style: TextStyle(color: AdminTheme.textSecondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children:
                      activities
                          .map(
                            (activity) => _buildActivityItem(context, activity),
                          )
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityItem activity) {
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
              color: activity.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Icon(activity.icon, color: activity.color, size: 20),
          ),

          const SizedBox(width: AdminTheme.spacingMd),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.title,
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
                  activity.subtitle,
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
              _formatTime(activity.timestamp),
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Simple date format if older than 7 days
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}



