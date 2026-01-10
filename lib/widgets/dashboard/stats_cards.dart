import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../common/glass_card.dart';
import '../common/animated_counter.dart';

class StatsCards extends StatefulWidget {
  const StatsCards({super.key});

  @override
  State<StatsCards> createState() => _StatsCardsState();
}

class _StatsCardsState extends State<StatsCards> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stats
  int totalUsers = 0;
  int totalCreators = 0;
  int onlineCreators = 0;
  int liveCreators = 0;
  double todayEarnings = 0.0;
  double totalEarnings = 0.0;
  int activeCalls = 0;
  int activeLives = 0;

  // Stream Subscriptions
  // final List<StreamSubscription> _subscriptions = []; // No longer needed with aggregate queries

  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    // for (var sub in _subscriptions) { // No longer needed
    //   sub.cancel();
    // }
    // _subscriptions.clear();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isInitialLoading = true);

    try {
      // 1. Total Users Count (Aggregate Query - Extremely cheap)
      final usersCount =
          await _firestore
              .collection('users')
              .where('role', isNotEqualTo: 'creator')
              .count()
              .get();

      // 2. Creators Aggregate (Total and Earnings)
      final creatorsSnapshot =
          await _firestore
              .collection('creators')
              .where('isApproved', isEqualTo: true)
              .get();

      // 3. Today's Earnings (Specific query)
      final todayStart = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );
      final transSnapshot =
          await _firestore
              .collection('transactions')
              .where('type', whereIn: ['voice', 'video'])
              .where('createdAt', isGreaterThanOrEqualTo: todayStart)
              .get();

      // 4. Active Calls and Lives (Lightweight listeners or one-time)
      final activeCallsSnap =
          await _firestore
              .collection('call_requests')
              .where('status', whereIn: ['accepted', 'ongoing'])
              .count()
              .get();

      final activeLivesSnap =
          await _firestore
              .collection('live_sessions')
              .where('status', whereIn: ['active', 'live'])
              .count()
              .get();

      if (mounted) {
        double creatorsTotalEarnings = 0.0;
        int online = 0;
        int live = 0;

        for (var doc in creatorsSnapshot.docs) {
          final data = doc.data();
          if (data['isOnline'] == true &&
              data['isBusy'] == false &&
              (data['isVoiceEnabled'] == true ||
                  data['isVideoEnabled'] == true ||
                  data['isLive'] == true)) {
            online++;
          }
          if (data['isLive'] == true) live++;
          creatorsTotalEarnings +=
              (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
        }

        double today = 0.0;
        for (var doc in transSnapshot.docs) {
          today += ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0) * 0.2;
        }

        setState(() {
          totalUsers = usersCount.count ?? 0;
          totalCreators = creatorsSnapshot.docs.length;
          onlineCreators = online;
          liveCreators = live;
          totalEarnings = creatorsTotalEarnings;
          todayEarnings = today;
          activeCalls = activeCallsSnap.count ?? 0;
          activeLives = activeLivesSnap.count ?? 0;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Stats] Error fetching initial stats: $e');
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _setupRealTimeListeners() {
    // We removed global listeners to save costs.
    // Real-time updates for critical small numbers can be added here if needed.
    // Like active calls or lives which change frequently.
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        title: 'Total Users',
        value: totalUsers.toDouble(),
        icon: Icons.people_rounded,
        color: AdminTheme.electricBlue,
        trend: '+12%',
        isPositive: true,
      ),
      _StatItem(
        title: 'Total Creators',
        value: totalCreators.toDouble(),
        icon: Icons.star_rounded,
        color: AdminTheme.neonMagenta,
        trend: '+8%',
        isPositive: true,
      ),
      _StatItem(
        title: 'Online Creators',
        value: onlineCreators.toDouble(),
        icon: Icons.online_prediction_rounded,
        color: AdminTheme.successGreen,
        trend: '+5%',
        isPositive: true,
      ),
      _StatItem(
        title: 'Live Creators',
        value: liveCreators.toDouble(),
        icon: Icons.live_tv_rounded,
        color: AdminTheme.warningOrange,
        trend: '+15%',
        isPositive: true,
      ),
      _StatItem(
        title: 'Today Earnings',
        value: todayEarnings,
        icon: Icons.trending_up_rounded,
        color: AdminTheme.successGreen,
        trend: '+22%',
        isPositive: true,
        isCurrency: true,
      ),
      _StatItem(
        title: 'Total Earnings',
        value: totalEarnings,
        icon: Icons.account_balance_wallet_rounded,
        color: AdminTheme.primaryPurple,
        trend: '+18%',
        isPositive: true,
        isCurrency: true,
      ),
      _StatItem(
        title: 'Active Calls',
        value: activeCalls.toDouble(),
        icon: Icons.call_rounded,
        color: AdminTheme.infoBlue,
        trend: '+3%',
        isPositive: true,
      ),
      _StatItem(
        title: 'Active Lives',
        value: activeLives.toDouble(),
        icon: Icons.videocam_rounded,
        color: AdminTheme.errorRed,
        trend: '+7%',
        isPositive: true,
      ),
    ];

    return Column(
      children: [
        // Refresh & Indicator Header
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isInitialLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AdminTheme.primaryPurple),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              'Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
              style: const TextStyle(
                color: AdminTheme.textTertiary,
                fontSize: 10,
              ),
            ),
            IconButton(
              onPressed: _fetchStats,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AdminTheme.textSecondary,
              ),
              tooltip: 'Refresh Stats',
            ),
          ],
        ),
        const SizedBox(height: AdminTheme.spacingSm),
        if (app_utils.AppResponsiveUtils.isMobile(context))
          Column(
            children:
                stats
                    .map(
                      (stat) => Padding(
                        padding: EdgeInsets.only(
                          bottom: app_utils
                              .AppResponsiveUtils.responsiveSpacing(context),
                        ),
                        child: _buildStatCard(stat, context),
                      ),
                    )
                    .toList(),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: app_utils.AppResponsiveUtils.getGridColumns(
                context,
              ),
              crossAxisSpacing: app_utils.AppResponsiveUtils.responsiveSpacing(
                context,
              ),
              mainAxisSpacing: app_utils.AppResponsiveUtils.responsiveSpacing(
                context,
              ),
              childAspectRatio: app_utils.AppResponsiveUtils.getCardAspectRatio(
                context,
              ),
            ),
            itemCount: stats.length,
            itemBuilder:
                (context, index) => _buildStatCard(stats[index], context),
          ),
      ],
    );
  }

  Widget _buildStatCard(_StatItem stat, BuildContext context) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust icon size based on available space
    final iconSize = app_utils.AppResponsiveUtils.responsive(
      context,
      mobile: 32.0,
      tablet: screenWidth < 900 ? 36.0 : 42.0,
      desktop: 48.0,
    );

    return GlassCard(
      child: Container(
        padding: app_utils.AppResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            // Header with icon and trend
            Row(
              children: [
                // Icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  ),
                  child: Icon(
                    stat.icon,
                    color: stat.color,
                    size: iconSize * 0.5,
                  ),
                ),

                const Spacer(),

                // Only show trend if there's enough space
                if (!isMobile && screenWidth > 1100)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (stat.isPositive
                              ? AdminTheme.successGreen
                              : AdminTheme.errorRed)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stat.isPositive
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 9,
                          color:
                              stat.isPositive
                                  ? AdminTheme.successGreen
                                  : AdminTheme.errorRed,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          stat.trend,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            color:
                                stat.isPositive
                                    ? AdminTheme.successGreen
                                    : AdminTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(
              height: app_utils.AppResponsiveUtils.responsiveSpacing(context),
            ),

            // Value - Use FittedBox to handle horizontal scaling and ensure vertical space
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedCounter(
                value: stat.value,
                style: TextStyle(
                  fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 20,
                    tablet: 24,
                    desktop: 28,
                  ),
                  fontWeight: FontWeight.bold,
                  color: stat.color,
                  height: 1.2, // Give more vertical space to prevent clipping
                ),
                prefix: stat.isCurrency ? '₹' : '',
              ),
            ),

            const SizedBox(height: 4),

            // Title
            Text(
              stat.title,
              style: TextStyle(
                fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                ),
                color: AdminTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;
  final bool isCurrency;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
    this.isCurrency = false,
  });
}
