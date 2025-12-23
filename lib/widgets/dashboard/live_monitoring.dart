import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../common/glass_card.dart';

class LiveMonitoring extends StatefulWidget {
  const LiveMonitoring({super.key});

  @override
  State<LiveMonitoring> createState() => _LiveMonitoringState();
}

class _LiveMonitoringState extends State<LiveMonitoring> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AdminTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.live_tv_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: AdminTheme.spacingMd),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Live Monitoring',
                        style: TextStyle(
                          fontSize: app_utils
                              .AppResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 16,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Real-time activity',
                        style: TextStyle(
                          fontSize: app_utils
                              .AppResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 12,
                          ),
                          color: AdminTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AdminTheme.successGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingXl),

            // Live calls section
            _buildLiveCallsSection(),

            const SizedBox(height: AdminTheme.spacingLg),

            // Live streams section
            _buildLiveStreamsSection(),

            const SizedBox(height: AdminTheme.spacingLg),

            // Recent activities
            _buildRecentActivitiesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCallsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('call_requests')
              .where('status', isEqualTo: 'ongoing')
              .limit(3)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingSection('Active Calls');
        }

        final calls = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Active Calls',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Text(
                    '${calls.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminTheme.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingMd),

            if (calls.isEmpty)
              _buildEmptyState('No active calls')
            else
              ...calls.map(
                (doc) => _buildCallItem(doc.data() as Map<String, dynamic>),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLiveStreamsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('live_sessions')
              .where('isActive', isEqualTo: true)
              .limit(3)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingSection('Live Streams');
        }

        final streams = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Live Streams',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTheme.errorRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Text(
                    '${streams.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingMd),

            if (streams.isEmpty)
              _buildEmptyState('No live streams')
            else
              ...streams.map(
                (doc) => _buildStreamItem(doc.data() as Map<String, dynamic>),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AdminTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AdminTheme.spacingMd),

        _buildActivityItem(
          icon: Icons.person_add,
          title: 'New user registered',
          subtitle: '2 minutes ago',
          color: AdminTheme.electricBlue,
        ),

        _buildActivityItem(
          icon: Icons.call,
          title: 'Voice call completed',
          subtitle: '5 minutes ago',
          color: AdminTheme.successGreen,
        ),

        _buildActivityItem(
          icon: Icons.star,
          title: 'Creator went live',
          subtitle: '8 minutes ago',
          color: AdminTheme.warningOrange,
        ),
      ],
    );
  }

  Widget _buildCallItem(Map<String, dynamic> data) {
    final callerName = data['callerName'] ?? 'Unknown';
    final creatorName = data['creatorName'] ?? 'Unknown';
    final callType = data['callType'] ?? 'voice';
    final duration = _calculateDuration(data['startTime']);

    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminTheme.cardDarker.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AdminTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Icon(
              callType == 'video' ? Icons.videocam : Icons.call,
              color: AdminTheme.successGreen,
              size: 14,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$callerName → $creatorName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AdminTheme.successGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamItem(Map<String, dynamic> data) {
    final creatorName = data['creatorName'] ?? 'Unknown';
    final viewerCount = data['viewerCount'] ?? 0;
    final duration = _calculateDuration(data['startTime']);

    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminTheme.cardDarker.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AdminTheme.errorRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: const Icon(
              Icons.live_tv,
              color: AdminTheme.errorRed,
              size: 14,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  creatorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$viewerCount viewers • $duration',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AdminTheme.errorRed,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 14),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AdminTheme.spacingMd),
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.primaryPurple),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminTheme.cardDarker.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.borderColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          message,
          style: AdminTheme.bodyMedium.copyWith(
            color: AdminTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  String _calculateDuration(dynamic startTime) {
    if (startTime == null) return '0:00';

    final start = (startTime as Timestamp).toDate();
    final duration = DateTime.now().difference(start);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

