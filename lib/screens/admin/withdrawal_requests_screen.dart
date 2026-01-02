import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../services/withdrawal_service.dart';
import '../../services/kyc_service.dart';
import '../../models/withdrawal_request.dart';
import '../../models/kyc_submission.dart';
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
  final KYCService _kycService = KYCService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AdminTheme.cardDark,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: AdminTheme.borderColor.withOpacity(0.3)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: AdminTheme.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(
                color: AdminTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            labelColor: AdminTheme.primaryPurple,
            unselectedLabelColor: AdminTheme.textSecondary,
            tabs: const [
              Tab(text: 'Pending Withdraws'),
              Tab(text: 'KYC Approvals'),
              Tab(text: 'History'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(isHistory: false),
              _buildKYCList(),
              _buildHistoryList(),
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
        final screenWidth = MediaQuery.of(context).size.width;
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
                  app_utils.AppResponsiveUtils.isTablet(context) ? 1 : 2,
              childAspectRatio: screenWidth < 1300 ? 1.35 : 1.6,
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

  Future<Map<String, dynamic>?> _fetchCreatorDetails(
    String creatorId,
    Map<String, dynamic> existingBankDetails,
  ) async {
    try {
      // 1. Try to get creator profile
      final doc =
          await FirebaseFirestore.instance
              .collection('creators')
              .doc(creatorId)
              .get();

      Map<String, dynamic> bankData = Map.from(existingBankDetails);
      String? name;
      String? photoUrl;

      if (doc.exists) {
        final data = doc.data()!;
        name = data['name'] ?? data['displayName'];
        photoUrl = data['photoUrl'];

        if (bankData.isEmpty) {
          final profileBank =
              data['kyc'] ?? data['bankDetails'] ?? data['paymentDetails'];
          if (profileBank is Map<String, dynamic>) {
            bankData = profileBank;
          }
        }
      }

      // 2. If bank details still missing, check kyc_submissions collection specifically
      if (bankData.isEmpty) {
        final kycDoc =
            await FirebaseFirestore.instance
                .collection('kyc_submissions')
                .doc(creatorId) // Using UID as ID based on Image 1
                .get();

        if (kycDoc.exists) {
          final data = kycDoc.data()!;
          name ??= data['fullName'] ?? data['name'];

          // Map fields from KYC submission to Bank Details format
          bankData = {
            'accountHolderName': data['accountHolderName'] ?? data['fullName'],
            'bankName': data['bankName'],
            'ifscCode': data['ifscCode'],
            'accountNumber': data['paymentDetails'],
            'panNumber': data['panNumber'],
            'upiId': data['upiId'],
          }..removeWhere((k, v) => v == null);
        }
      }

      return {'name': name, 'photoUrl': photoUrl, 'bankDetails': bankData};
    } catch (e) {
      debugPrint('Error fetching creator details: $e');
    }
    return null;
  }

  Widget _buildRequestCard(WithdrawalRequest request, bool isHistory) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchCreatorDetails(request.creatorId, request.bankDetails),
      builder: (context, snapshot) {
        final creatorData = snapshot.data;
        final name =
            creatorData?['name'] ?? request.creatorName ?? 'Unknown Creator';
        final photoUrl = creatorData?['photoUrl'] ?? request.creatorPhotoUrl;
        final bankDetails = creatorData?['bankDetails'] ?? request.bankDetails;

        final currencyFormat = NumberFormat.currency(
          symbol: '₹',
          decimalDigits: 2,
        );

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
                      backgroundColor: AdminTheme.primaryPurple.withOpacity(
                        0.2,
                      ),
                      backgroundImage:
                          photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                      child:
                          photoUrl == null || photoUrl.isEmpty
                              ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                            name,
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
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm,
                        ),
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
                if (app_utils.AppResponsiveUtils.isMobile(context)) ...[
                  Column(
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
                      const SizedBox(height: AdminTheme.spacingMd),
                      _buildBankDetailsContainer(bankDetails),
                    ],
                  ),
                ] else ...[
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
                        child: _buildBankDetailsContainer(bankDetails),
                      ),
                    ],
                  ),
                ],

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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AdminTheme.radiusSm,
                              ),
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingMd),
                      Expanded(
                        child: AnimatedButton(
                          onPressed: () => _handleApprove(context, request),
                          backgroundColor: AdminTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
      },
    );
  }

  Widget _buildBankDetailsContainer(Map<String, dynamic> bankDetails) {
    return Container(
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
                  final details = bankDetails.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n');
                  Clipboard.setData(ClipboardData(text: details));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bank details copied to clipboard'),
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
          if (bankDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No bank details found in request or KYC',
                style: TextStyle(
                  color: AdminTheme.errorRed,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...bankDetails.entries.map((e) {
              String label = e.key;
              // Mapping common keys to readable labels
              final Map<String, String> keyMapping = {
                'accNo': 'Account No',
                'accNum': 'Account No',
                'account_no': 'Account No',
                'account_number': 'Account No',
                'accountNumber': 'Account No',
                'ifsc': 'IFSC Code',
                'ifsc_code': 'IFSC Code',
                'ifscCode': 'IFSC Code',
                'bankName': 'Bank Name',
                'bank_name': 'Bank Name',
                'bank': 'Bank Name',
                'accHolderName': 'A/C Holder',
                'accountHolderName': 'A/C Holder',
                'holderName': 'A/C Holder',
                'panNumber': 'PAN Number',
                'pan': 'PAN Number',
                'upi': 'UPI ID',
                'upi_id': 'UPI ID',
                'upiId': 'UPI ID',
                'branch': 'Branch',
                'branch_name': 'Branch',
              };

              if (keyMapping.containsKey(e.key)) {
                label = keyMapping[e.key]!;
              } else {
                // Convert camelCase or snake_case to Title Case
                label =
                    e.key
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (match) => ' ${match.group(0)}',
                        )
                        .replaceAll('_', ' ')
                        .trim();
                if (label.isNotEmpty) {
                  label = label[0].toUpperCase() + label.substring(1);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 85,
                      child: Text(
                        '$label: ',
                        style: const TextStyle(
                          color: AdminTheme.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        e.value.toString(),
                        style: const TextStyle(
                          color: AdminTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildKYCList() {
    return StreamBuilder<List<KYCSubmission>>(
      stream: _kycService.getPendingKYC(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AdminTheme.errorRed),
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

        final kycList = snapshot.data!;

        if (kycList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: AdminTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AdminTheme.spacingMd),
                const Text(
                  'No pending KYC approvals',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AdminTheme.spacingLg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                app_utils.AppResponsiveUtils.isMobile(context)
                    ? 1
                    : app_utils.AppResponsiveUtils.isTablet(context)
                    ? 2
                    : 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: AdminTheme.spacingMd,
            mainAxisSpacing: AdminTheme.spacingMd,
          ),
          itemCount: kycList.length,
          itemBuilder: (context, index) {
            return _buildKYCCard(kycList[index]);
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AdminTheme.spacingLg),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                color: AdminTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent History (Withdrawals & KYC)',
                style: AdminTheme.headlineSmall.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
        Expanded(child: _buildRequestList(isHistory: true)),
      ],
    );
  }

  Widget _buildKYCCard(KYCSubmission kyc) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTheme.primaryPurple.withOpacity(0.2),
                  child: Text(
                    kyc.fullName.isNotEmpty
                        ? kyc.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AdminTheme.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kyc.fullName,
                        style: const TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(kyc.createdAt),
                        style: const TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingMd),
            const Divider(color: AdminTheme.borderColor),
            const SizedBox(height: AdminTheme.spacingMd),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildKYCDetailRow('PAN', kyc.panNumber ?? 'N/A'),
                    _buildKYCDetailRow('Bank', kyc.bankName ?? 'N/A'),
                    _buildKYCDetailRow('A/C No', kyc.paymentDetails ?? 'N/A'),
                    _buildKYCDetailRow('IFSC', kyc.ifscCode ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AdminTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleKYCReject(context, kyc),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.errorRed,
                      side: const BorderSide(color: AdminTheme.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm,
                        ),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingMd),
                Expanded(
                  child: AnimatedButton(
                    onPressed: () => _handleKYCApprove(context, kyc),
                    backgroundColor: AdminTheme.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Approve',
                      style: TextStyle(color: AdminTheme.backgroundPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKYCDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AdminTheme.textTertiary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleKYCApprove(
    BuildContext context,
    KYCSubmission kyc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _kycService.approveKYC(kyc.id, kyc.uid);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('KYC for ${kyc.fullName} approved'),
            backgroundColor: AdminTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleKYCReject(BuildContext context, KYCSubmission kyc) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text('Reject KYC'),
            content: TextField(
              controller: reasonController,
              style: const TextStyle(color: AdminTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Reason for rejection',
              ),
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
        await _kycService.rejectKYC(kyc.id, kyc.uid, reasonController.text);
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('KYC rejected')));
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AdminTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleApprove(
    BuildContext context,
    WithdrawalRequest request,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
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
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment processed successfully'),
              backgroundColor: AdminTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
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
    final messenger = ScaffoldMessenger.of(context);
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
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: AdminTheme.textPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
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
