import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_theme.dart';
import '../../services/withdrawal_service.dart';
import '../../models/withdrawal_request.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_button.dart';
import '../../utils/responsive_utils.dart' as app_utils;

class WithdrawalRequestsScreen extends StatefulWidget {
  final bool isEmbedded;

  const WithdrawalRequestsScreen({super.key, this.isEmbedded = false});

  @override
  State<WithdrawalRequestsScreen> createState() =>
      _WithdrawalRequestsScreenState();
}

class _WithdrawalRequestsScreenState extends State<WithdrawalRequestsScreen>
    with SingleTickerProviderStateMixin {
  final WithdrawalService _withdrawalService = WithdrawalService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Tabs
        Container(
          margin: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
          decoration: BoxDecoration(
            color: AdminTheme.cardDark,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: AdminTheme.borderColor.withOpacity(0.3)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AdminTheme.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(
                color: AdminTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
            labelColor: AdminTheme.primaryPurple,
            unselectedLabelColor: AdminTheme.textSecondary,
            tabs: const [Tab(text: 'Pending Requests'), Tab(text: 'History')],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(isHistory: false),
              _buildRequestList(isHistory: true),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingLg),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AdminTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Withdrawal Requests',
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
      body: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingLg),
        child: content,
      ),
    );
  }

  Widget _buildRequestList({required bool isHistory}) {
    return StreamBuilder<List<WithdrawalRequest>>(
      stream:
          isHistory
              ? _withdrawalService.getAllRequests()
              : _withdrawalService.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ [WithdrawalRequestsScreen] Error: ${snapshot.error}');
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
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

        final requests = snapshot.data!;

        final displayRequests =
            isHistory
                ? requests.where((r) => r.status != 'pending').toList()
                : requests;

        if (displayRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHistory ? Icons.history : Icons.inbox,
                  size: 64,
                  color: AdminTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AdminTheme.spacingMd),
                Text(
                  isHistory ? 'No withdrawal history' : 'No pending requests',
                  style: AdminTheme.headlineSmall.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (app_utils.AppResponsiveUtils.isMobile(context)) {
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
            itemCount: displayRequests.length,
            separatorBuilder:
                (context, index) =>
                    const SizedBox(height: AdminTheme.spacingMd),
            itemBuilder: (context, index) {
              return _buildRequestCard(displayRequests[index], isHistory);
            },
          );
        } else {
          return GridView.builder(
            padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  app_utils.AppResponsiveUtils.isTablet(context) ? 2 : 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: AdminTheme.spacingMd,
              mainAxisSpacing: AdminTheme.spacingMd,
            ),
            itemCount: displayRequests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(displayRequests[index], isHistory);
            },
          );
        }
      },
    );
  }

  Widget _buildRequestCard(WithdrawalRequest request, bool isHistory) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AdminTheme.primaryPurple.withOpacity(0.2),
                  backgroundImage:
                      request.creatorPhotoUrl != null &&
                              request.creatorPhotoUrl!.isNotEmpty
                          ? NetworkImage(request.creatorPhotoUrl!)
                          : null,
                  child:
                      request.creatorPhotoUrl == null ||
                              request.creatorPhotoUrl!.isEmpty
                          ? Text(
                            (request.creatorName?.isNotEmpty ?? false)
                                ? request.creatorName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AdminTheme.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: AdminTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.creatorName ?? 'Unknown Creator',
                        style: const TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM d, y • h:mm a',
                        ).format(request.createdAt),
                        style: const TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    border: Border.all(
                      color: request.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: request.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingMd),
            const Divider(color: AdminTheme.borderColor),
            const SizedBox(height: AdminTheme.spacingMd),

            // Amount & Bank Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount Requested',
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(request.amount),
                        style: const TextStyle(
                          color: AdminTheme.successGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(AdminTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AdminTheme.backgroundPrimary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bank Details',
                              style: TextStyle(
                                color: AdminTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final details = request.bankDetails.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('\n');
                                Clipboard.setData(ClipboardData(text: details));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bank details copied to clipboard',
                                    ),
                                    backgroundColor: AdminTheme.successGreen,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.copy,
                                size: 14,
                                color: AdminTheme.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...request.bankDetails.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${e.key}: ',
                                  style: const TextStyle(
                                    color: AdminTheme.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: SelectableText(
                                    e.value.toString(),
                                    style: const TextStyle(
                                      color: AdminTheme.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (!isHistory) ...[
              const SizedBox(height: AdminTheme.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleReject(context, request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.errorRed,
                        side: const BorderSide(color: AdminTheme.errorRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AdminTheme.spacingMd),
                  Expanded(
                    child: AnimatedButton(
                      onPressed: () => _handleApprove(context, request),
                      backgroundColor: AdminTheme.successGreen,
                      child: const Text(
                        'Process Payment',
                        style: TextStyle(
                          color: AdminTheme.backgroundPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WithdrawalRequest request,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'Confirm Payment',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: Text(
              'Are you sure you want to mark this request of ₹${request.amount} as processed?',
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              AnimatedButton(
                onPressed: () => Navigator.pop(context, true),
                backgroundColor: AdminTheme.successGreen,
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: AdminTheme.backgroundPrimary),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _withdrawalService.approveRequest(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment processed successfully'),
              backgroundColor: AdminTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AdminTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WithdrawalRequest request,
  ) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'Reject Request',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please provide a reason for rejection:',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Reason (e.g., Invalid bank details)',
                    hintStyle: TextStyle(color: AdminTheme.textTertiary),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AdminTheme.errorRed,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _withdrawalService.rejectRequest(
          request.id,
          reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: AdminTheme.textPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AdminTheme.errorRed,
            ),
          );
        }
      }
    }
  }
}
