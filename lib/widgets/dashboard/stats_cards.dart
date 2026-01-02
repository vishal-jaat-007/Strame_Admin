import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    // Listen to users collection for total users count (only viewers)
    _firestore
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              int viewersCount = 0;
              for (var doc in snapshot.docs) {
                final data = doc.data();
                final role = data['role'] as String?;

                // Exclude creators from total users count
                if (role != 'creator') {
                  viewersCount++;
                }
              }

              setState(() {
                totalUsers = viewersCount;
              });
              debugPrint('📊 [Stats] Total Users (Viewers only): $totalUsers');
            }
          },
          onError: (e) {
            debugPrint('❌ [Stats] Error fetching users: $e');
          },
        );

    // Listen to creators collection for online status, live status, and earnings
    _firestore
        .collection('creators')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              double creatorsTotalEarnings = 0.0;
              int online = 0;
              int live = 0;
              int approved = 0;

              for (var doc in snapshot.docs) {
                final data = doc.data();

                // Count approved creators (actual total creators)
                if (data['isApproved'] == true) {
                  approved++;
                }

                // Count online creators (matching app logic exactly)
                // Creator is "online" if: isOnline=true AND NOT busy AND at least one mode enabled
                final isOnline = data['isOnline'] == true;
                final isBusy = data['isBusy'] == true;
                final isVoiceEnabled = data['isVoiceEnabled'] == true;
                final isVideoEnabled = data['isVideoEnabled'] == true;
                final isLive = data['isLive'] == true;

                if (isOnline &&
                    !isBusy &&
                    (isVoiceEnabled || isVideoEnabled || isLive)) {
                  online++;
                }

                // Count live creators
                if (isLive) {
                  live++;
                }

                // Sum up total earnings from all creators
                final earnings =
                    (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
                creatorsTotalEarnings += earnings;
              }

              setState(() {
                // Total Creators = only approved (verified) creators
                totalCreators = approved;
                onlineCreators = online;
                liveCreators = live;
                totalEarnings = creatorsTotalEarnings;
              });

              debugPrint(
                '📊 [Stats] Total Creators (Verified): $totalCreators, Online: $onlineCreators, Live: $liveCreators',
              );
              debugPrint(
                '📊 [Stats] Total Earnings (sum of all creators): ₹$totalEarnings',
              );
            }
          },
          onError: (e) {
            debugPrint('❌ [Stats] Error fetching creators: $e');
          },
        );

    // Listen to transactions for today's earnings
    _firestore
        .collection('transactions')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              double today = 0.0;
              final todayStart = DateTime.now().copyWith(
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 0,
              );

              for (var doc in snapshot.docs) {
                final data = doc.data();
                final type = data['type'] as String?;

                // Only count call earnings (voice/video), not recharges
                if (type == 'voice' || type == 'video') {
                  final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

                  if (timestamp != null && timestamp.isAfter(todayStart)) {
                    // Convert coins to rupees: amount is in coins, convert to rupees
                    // 5 coins = 1 rupee
                    final coinsAmount =
                        (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final rupeesAmount =
                        coinsAmount * 0.2; // 1 coin = 0.2 rupees
                    today += rupeesAmount;
                  }
                }
              }

              setState(() {
                todayEarnings = today;
              });
              debugPrint('📊 [Stats] Today Earnings: ₹$todayEarnings');
            }
          },
          onError: (e) {
            debugPrint('❌ [Stats] Error fetching transactions: $e');
          },
        );

    // Listen to call requests for active calls (both 'accepted' and 'ongoing')
    _firestore
        .collection('call_requests')
        .where('status', whereIn: ['accepted', 'ongoing'])
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                activeCalls = snapshot.docs.length;
              });
              debugPrint('📊 [Stats] Active Calls: $activeCalls');
            }
          },
          onError: (e) {
            debugPrint('❌ [Stats] Error fetching active calls: $e');
          },
        );

    // Listen to live sessions for active lives
    _firestore
        .collection('live_sessions')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              int count = 0;
              for (var doc in snapshot.docs) {
                final data = doc.data();
                final status = data['status'] as String?;
                final isActive = data['isActive'] == true;

                if (status == 'active' || status == 'live' || isActive) {
                  count++;
                }
              }
              setState(() {
                activeLives = count;
              });
              debugPrint('📊 [Stats] Active Lives: $activeLives');
            }
          },
          onError: (e) {
            debugPrint('❌ [Stats] Error fetching live sessions: $e');
          },
        );
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
