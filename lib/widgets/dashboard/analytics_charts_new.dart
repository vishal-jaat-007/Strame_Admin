import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../utils/responsive_utils.dart';
import '../common/glass_card.dart';

class AnalyticsCharts extends StatefulWidget {
  const AnalyticsCharts({super.key});

  @override
  State<AnalyticsCharts> createState() => _AnalyticsChartsState();
}

class _AnalyticsChartsState extends State<AnalyticsCharts>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FlSpot> earningsData = [];
  List<FlSpot> usersData = [];
  List<FlSpot> callsData = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    try {
      await Future.wait([
        _loadEarningsData(),
        _loadUsersData(),
        _loadCallsData(),
      ]);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chart data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEarningsData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final snapshot =
        await _firestore
            .collection('transactions')
            .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
            .get();

    final Map<int, double> dailyEarnings = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['createdAt'] as Timestamp).toDate();
      final amount = (data['amount'] ?? 0).toDouble();
      final dayIndex = now.difference(timestamp).inDays;

      if (dayIndex >= 0 && dayIndex < 7) {
        dailyEarnings[6 - dayIndex] =
            (dailyEarnings[6 - dayIndex] ?? 0) + amount;
      }
    }

    earningsData = List.generate(7, (index) {
      return FlSpot(index.toDouble(), dailyEarnings[index] ?? 0);
    });
  }

  Future<void> _loadUsersData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final snapshot =
        await _firestore
            .collection('users')
            .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
            .get();

    final Map<int, int> dailyUsers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['createdAt'] as Timestamp).toDate();
      final dayIndex = now.difference(timestamp).inDays;

      if (dayIndex >= 0 && dayIndex < 7) {
        dailyUsers[6 - dayIndex] = (dailyUsers[6 - dayIndex] ?? 0) + 1;
      }
    }

    usersData = List.generate(7, (index) {
      return FlSpot(index.toDouble(), (dailyUsers[index] ?? 0).toDouble());
    });
  }

  Future<void> _loadCallsData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final snapshot =
        await _firestore
            .collection('call_requests')
            .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
            .get();

    final Map<int, int> dailyCalls = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['createdAt'] as Timestamp).toDate();
      final dayIndex = now.difference(timestamp).inDays;

      if (dayIndex >= 0 && dayIndex < 7) {
        dailyCalls[6 - dayIndex] = (dailyCalls[6 - dayIndex] ?? 0) + 1;
      }
    }

    callsData = List.generate(7, (index) {
      return FlSpot(index.toDouble(), (dailyCalls[index] ?? 0).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Container(
        padding: AppResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            SizedBox(height: AppResponsiveUtils.responsiveSpacing(context)),

            // Chart
            _buildChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = AppResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Analytics Overview',
            style: TextStyle(
              fontSize: AppResponsiveUtils.responsiveFontSize(
                context,
                mobile: 18,
              ),
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),

          SizedBox(height: AppResponsiveUtils.responsiveSpacing(context) * 0.5),

          _buildTabBar(context),
        ],
      );
    }

    return Row(
      children: [
        Flexible(
          child: Text(
            'Analytics Overview',
            style: TextStyle(
              fontSize: AppResponsiveUtils.responsiveFontSize(
                context,
                mobile: 20,
              ),
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(width: AppResponsiveUtils.responsiveSpacing(context)),

        _buildTabBar(context),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isMobile = AppResponsiveUtils.isMobile(context);
    final tabBarWidth = AppResponsiveUtils.responsive(
      context,
      mobile: double.infinity,
      tablet: 280.0,
      desktop: 300.0,
    );

    return SizedBox(
      width: isMobile ? null : tabBarWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.cardDarker,
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isMobile ? 'Earn' : 'Earnings'),
            Tab(text: 'Users'),
            Tab(text: 'Calls'),
          ],
          indicator: BoxDecoration(
            gradient: AdminTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AdminTheme.textSecondary,
          labelStyle: TextStyle(
            fontSize: AppResponsiveUtils.responsiveFontSize(
              context,
              mobile: 12,
            ),
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: AppResponsiveUtils.responsiveFontSize(
              context,
              mobile: 12,
            ),
          ),
          dividerColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final chartHeight = AppResponsiveUtils.responsive(
      context,
      mobile: 200.0,
      tablet: 250.0,
      desktop: 300.0,
    );

    return SizedBox(
      height: chartHeight,
      child:
          isLoading
              ? _buildLoadingChart(context)
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildEarningsChart(),
                  _buildUsersChart(),
                  _buildCallsChart(),
                ],
              ),
    );
  }

  Widget _buildLoadingChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.primaryPurple),
          ),
          SizedBox(height: AppResponsiveUtils.responsiveSpacing(context) * 0.5),
          Text(
            'Loading analytics data...',
            style: TextStyle(
              fontSize: AppResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
              ),
              color: AdminTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    return LineChart(
      LineChartData(
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY:
            earningsData.isEmpty
                ? 100
                : earningsData.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                    1.2,
        lineBarsData: [
          LineChartBarData(
            spots: earningsData,
            isCurved: true,
            gradient: AdminTheme.primaryGradient,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AdminTheme.primaryPurple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AdminTheme.primaryPurple.withOpacity(0.3),
                  AdminTheme.primaryPurple.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersChart() {
    return LineChart(
      LineChartData(
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY:
            usersData.isEmpty
                ? 100
                : usersData.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                    1.2,
        lineBarsData: [
          LineChartBarData(
            spots: usersData,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AdminTheme.electricBlue, AdminTheme.neonMagenta],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AdminTheme.electricBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AdminTheme.electricBlue.withOpacity(0.3),
                  AdminTheme.electricBlue.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsChart() {
    return LineChart(
      LineChartData(
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY:
            callsData.isEmpty
                ? 100
                : callsData.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                    1.2,
        lineBarsData: [
          LineChartBarData(
            spots: callsData,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AdminTheme.successGreen, AdminTheme.warningOrange],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AdminTheme.successGreen,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AdminTheme.successGreen.withOpacity(0.3),
                  AdminTheme.successGreen.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AdminTheme.borderColor.withOpacity(0.2),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final index = value.toInt();
            if (index >= 0 && index < days.length) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontSize: AppResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 10,
                    ),
                    color: AdminTheme.textSecondary,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 42,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: AppResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 10,
                  ),
                  color: AdminTheme.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
