import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/admin_theme.dart';
import '../../../widgets/common/glass_card.dart';
import '../../../services/export_service.dart';

class ReportsModule extends StatefulWidget {
  const ReportsModule({super.key});

  @override
  State<ReportsModule> createState() => _ReportsModuleState();
}

class _ReportsModuleState extends State<ReportsModule> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  Map<String, dynamic> _stats = {
    'totalRevenue': 0.0,
    'todayRevenue': 0.0,
    'totalCalls': 0,
    'totalUsers': 0,
    'totalCreators': 0,
    'pendingCreators': 0,
    'pendingWithdrawals': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Fetch Users
      final usersSnapshot = await _firestore.collection('users').get();

      // Fetch Creators
      final creatorsSnapshot = await _firestore.collection('creators').get();

      // Fetch Transactions for Revenue
      final transactionsSnapshot =
          await _firestore.collection('transactions').get();

      // Fetch Withdrawals
      final withdrawalsSnapshot =
          await _firestore
              .collection('withdraw_requests')
              .where('status', isEqualTo: 'pending')
              .get();

      double totalRev = 0;
      double todayRev = 0;
      int callCount = 0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

        if (type == 'voice' || type == 'video' || type == 'chat') {
          callCount++;
          // 5 coins = 1 rupee logic
          final rupeeValue = amount * 0.2;
          totalRev += rupeeValue;

          if (timestamp != null && timestamp.isAfter(todayStart)) {
            todayRev += rupeeValue;
          }
        }
      }

      final creatorsDocs = creatorsSnapshot.docs;
      final approvedCreatorsCount =
          creatorsDocs.where((doc) => doc.data()['isApproved'] == true).length;
      final pendingCreatorsCount =
          creatorsDocs.where((doc) => doc.data()['isApproved'] == false).length;

      setState(() {
        _stats = {
          'totalRevenue': totalRev,
          'todayRevenue': todayRev,
          'totalCalls': callCount,
          'totalUsers': usersSnapshot.docs.length,
          'totalCreators': approvedCreatorsCount,
          'pendingCreators': pendingCreatorsCount,
          'pendingWithdrawals': withdrawalsSnapshot.docs.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing platform report...'),
        backgroundColor: AdminTheme.primaryPurple,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // 1. Fetch detailed Transactions for the report (last 500)
      final txSnapshot =
          await _firestore
              .collection('transactions')
              .orderBy('createdAt', descending: true)
              .limit(500)
              .get();

      List<List<dynamic>> txRows =
          txSnapshot.docs.map((doc) {
            final data = doc.data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final timestamp =
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return [
              DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
              data['type'] ?? 'unknown',
              amount,
              '₹${(amount * 0.2).toStringAsFixed(2)}',
              data['status'] ?? 'success',
              data['description'] ?? '',
            ];
          }).toList();

      // 2. Fetch Creator Summary
      final creatorsSnapshot = await _firestore.collection('creators').get();
      List<List<dynamic>> creatorRows =
          creatorsSnapshot.docs.take(100).map((doc) {
            final data = doc.data();
            final earnings = (data['totalEarnings'] ?? 0) as num;
            return [
              data['displayName'] ?? doc.id,
              (data['isApproved'] == true) ? 'Certified' : 'In Review',
              '₹${(earnings * 0.2).toStringAsFixed(2)}',
            ];
          }).toList();

      // 3. Trigger Download
      ExportService.exportToCsv(
        summaryStats: _stats,
        transactionData: txRows,
        creatorData: creatorRows,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report downloaded successfully!'),
            backgroundColor: AdminTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Export Failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? AdminTheme.spacingMd : AdminTheme.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analytics Reports', style: AdminTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Real-time platform performance overview',
                  style: AdminTheme.bodySmall.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleExport,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export Full Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics Reports', style: AdminTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time platform performance overview',
                      style: AdminTheme.bodySmall.copyWith(
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _handleExport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Full Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AdminTheme.spacingXl),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            childAspectRatio: isMobile ? 2.2 : (isTablet ? 1.4 : 1.3),
            crossAxisSpacing: AdminTheme.spacingLg,
            mainAxisSpacing: AdminTheme.spacingLg,
            children: [
              _buildReportStatCard(
                'Total Revenue',
                '₹${_stats['totalRevenue'].toStringAsFixed(2)}',
                Icons.payments_rounded,
                AdminTheme.successGreen,
              ),
              _buildReportStatCard(
                'Today Revenue',
                '₹${_stats['todayRevenue'].toStringAsFixed(2)}',
                Icons.trending_up,
                AdminTheme.electricBlue,
              ),
              _buildReportStatCard(
                'Total Interactions',
                '${_stats['totalCalls']}',
                Icons.call_rounded,
                AdminTheme.neonMagenta,
              ),
              _buildReportStatCard(
                'Platform Users',
                '${_stats['totalUsers']}',
                Icons.people_rounded,
                AdminTheme.infoBlue,
              ),
              _buildReportStatCard(
                'Active Creators',
                '${_stats['totalCreators']}',
                Icons.verified_user_rounded,
                AdminTheme.warningOrange,
              ),
              _buildReportStatCard(
                'Approval Queue',
                '${_stats['pendingCreators']}',
                Icons.pending_actions_rounded,
                AdminTheme.neonMagenta,
              ),
              _buildReportStatCard(
                'Pending Payouts',
                '${_stats['pendingWithdrawals']}',
                Icons.account_balance_wallet_rounded,
                AdminTheme.errorRed,
              ),
              _buildReportStatCard(
                'Internal Stats',
                '${_stats['totalCalls']}',
                Icons.analytics_rounded,
                AdminTheme.primaryPurple,
              ),
            ],
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          // Detailed Table or Chart
          GlassCard(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Overview', style: AdminTheme.headlineSmall),
                const SizedBox(height: 20),
                _buildListRow(
                  'Active Users',
                  '${_stats['totalUsers']}',
                  0.85,
                  AdminTheme.infoBlue,
                ),
                _buildListRow(
                  'Creator Growth',
                  '${(_stats['totalCreators'] / 10).toStringAsFixed(1)}%',
                  0.65,
                  AdminTheme.warningOrange,
                ),
                _buildListRow(
                  'Revenue Conversion',
                  '₹${(_stats['totalRevenue'] / 100).toStringAsFixed(2)}/user',
                  0.45,
                  AdminTheme.successGreen,
                ),
                _buildListRow(
                  'Payout Efficiency',
                  '98%',
                  0.98,
                  AdminTheme.primaryPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AdminTheme.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: AdminTheme.bodySmall.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AdminTheme.bodyMedium),
              Text(
                value,
                style: AdminTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
