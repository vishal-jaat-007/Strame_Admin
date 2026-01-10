import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/admin_theme.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/common/glass_card.dart';
import '../../utils/responsive_utils.dart' as app_utils;

class TransactionsScreen extends StatefulWidget {
  final bool isEmbedded;

  const TransactionsScreen({super.key, this.isEmbedded = false});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final List<TransactionModel> _transactions = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _transactions.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _transactionService.getTransactionsPaginated(
        limit: 20,
        startAfter: _lastDocument,
      );

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newTransactions =
          snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();

      setState(() {
        _transactions.addAll(newTransactions);
        _lastDocument = snapshot.docs.last;
        _isLoading = false;
        if (newTransactions.length < 20) _hasMore = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(
          child:
              _transactions.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      bottom: AdminTheme.spacingLg,
                    ),
                    children: [
                      if (app_utils.AppResponsiveUtils.isMobile(context))
                        ..._transactions.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AdminTheme.spacingMd,
                            ),
                            child: _buildTransactionCard(t),
                          ),
                        )
                      else
                        _buildGrid(context, _transactions),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AdminTheme.spacingMd),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      if (_hasMore && !_isLoading)
                        Center(
                          child: TextButton(
                            onPressed: _loadTransactions,
                            child: const Text('Load More'),
                          ),
                        ),
                      const SizedBox(height: 100),
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
          'Transactions',
          style: TextStyle(
            color: AdminTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AdminTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _loadTransactions(refresh: true),
            icon: const Icon(Icons.refresh, color: AdminTheme.textPrimary),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingLg),
        child: content,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: AdminTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Text(
            'No transactions found',
            style: AdminTheme.headlineSmall.copyWith(
              color: AdminTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<TransactionModel> transactions) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: app_utils.AppResponsiveUtils.isTablet(context) ? 2 : 3,
        childAspectRatio: screenWidth < 1200 ? 2.0 : 2.4,
        crossAxisSpacing: AdminTheme.spacingMd,
        mainAxisSpacing: AdminTheme.spacingMd,
      ),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(transactions[index]);
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    Color statusColor;
    switch (transaction.status.toLowerCase()) {
      case 'success':
        statusColor = AdminTheme.successGreen;
        break;
      case 'failed':
        statusColor = AdminTheme.errorRed;
        break;
      default:
        statusColor = AdminTheme.warningOrange;
    }

    IconData typeIcon;
    switch (transaction.type.toLowerCase()) {
      case 'withdrawal':
        typeIcon = Icons.arrow_upward;
        break;
      case 'gift':
        typeIcon = Icons.card_giftcard;
        break;
      case 'call_earning':
        typeIcon = Icons.phone_in_talk;
        break;
      default:
        typeIcon = Icons.attach_money;
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: AdminTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      transaction.description.isNotEmpty
                          ? transaction.description
                          : transaction.type.toUpperCase(),
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat(
                        'MMM d, y • h:mm a',
                      ).format(transaction.createdAt),
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AdminTheme.spacingMd),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currencyFormat.format(transaction.amount),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
}
