import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:responsive_framework/responsive_framework.dart';
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

  @override
  void initState() {
    super.initState();
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    // Listen to users collection
    _firestore.collection('users').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          totalUsers = snapshot.docs.length;
          totalCreators =
              snapshot.docs.where((doc) {
                final data = doc.data();
                return data['role'] == 'creator';
              }).length;
        });
      }
    });

    // Listen to creators collection for online status
    _firestore.collection('creators').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          onlineCreators =
              snapshot.docs.where((doc) {
                final data = doc.data();
                return data['isOnline'] == true;
              }).length;

          liveCreators =
              snapshot.docs.where((doc) {
                final data = doc.data();
                return data['isLive'] == true;
              }).length;
        });
      }
    });

    // Listen to transactions for earnings
    _firestore.collection('transactions').snapshots().listen((snapshot) {
      if (mounted) {
        double total = 0.0;
        double today = 0.0;
        final todayStart = DateTime.now().copyWith(
          hour: 0,
          minute: 0,
          second: 0,
        );

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] ?? 0).toDouble();
          final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

          total += amount;

          if (timestamp != null && timestamp.isAfter(todayStart)) {
            today += amount;
          }
        }

        setState(() {
          totalEarnings = total;
          todayEarnings = today;
        });
      }
    });

    // Listen to call requests for active calls
    _firestore
        .collection('call_requests')
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              activeCalls = snapshot.docs.length;
            });
          }
        });

    // Listen to live sessions for active lives
    _firestore
        .collection('live_sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              activeLives = snapshot.docs.length;
            });
          }
        });
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

    if (app_utils.AppResponsiveUtils.isMobile(context)) {
      return Column(
        children:
            stats
                .map(
                  (stat) => Padding(
                    padding: EdgeInsets.only(
                      bottom: app_utils.AppResponsiveUtils.responsiveSpacing(
                        context,
                      ),
                    ),
                    child: _buildStatCard(stat, context),
                  ),
                )
                .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: app_utils.AppResponsiveUtils.getGridColumns(context),
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
      itemBuilder: (context, index) => _buildStatCard(stats[index], context),
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
          mainAxisSize: MainAxisSize.min,
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

                // Only show trend if there's enough space (wider screens with 3+ columns)
                if (!isMobile && screenWidth > 1100)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (stat.isPositive
                                ? AdminTheme.successGreen
                                : AdminTheme.errorRed)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm,
                        ),
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
                          Flexible(
                            child: Text(
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
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(
              height: app_utils.AppResponsiveUtils.responsiveSpacing(context),
            ),

            // Value
            Flexible(
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
                ),
                prefix: stat.isCurrency ? '₹' : '',
              ),
            ),

            SizedBox(
              height:
                  app_utils.AppResponsiveUtils.responsiveSpacing(context) * 0.5,
            ),

            // Title
            Flexible(
              child: Text(
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
                maxLines: 2,
              ),
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
