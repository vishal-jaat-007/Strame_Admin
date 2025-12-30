import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../services/recent_activity_service.dart';
import 'package:intl/intl.dart';

class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  final RecentActivityService _activityService = RecentActivityService();
  final int _limit = 50; // Fetch more for "View All"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Activities',
          style: TextStyle(
            color: AdminTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AdminTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminTheme.spacingLg),
        child: StreamBuilder<List<ActivityItem>>(
          stream: _activityService.getActivitiesStream(limit: _limit),
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
                child: Text(
                  'No activities found',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              );
            }

            return Column(
              children:
                  activities
                      .map((activity) => _buildActivityItem(context, activity))
                      .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingMd),
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminTheme.cardDarker,
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
                    fontSize: 14,
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
                    fontSize: 12,
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
          Text(
            _formatTime(activity.timestamp),
            style: AdminTheme.labelSmall.copyWith(
              color: AdminTheme.textTertiary,
            ),
            textAlign: TextAlign.end,
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
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
