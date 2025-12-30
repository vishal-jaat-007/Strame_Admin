import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactions(),
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

        final transactions = snapshot.data!;

        if (transactions.isEmpty) {
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

        if (app_utils.AppResponsiveUtils.isMobile(context)) {
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
            itemCount: transactions.length,
            separatorBuilder:
                (context, index) =>
                    const SizedBox(height: AdminTheme.spacingMd),
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index]);
            },
          );
        } else {
          return GridView.builder(
            padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  app_utils.AppResponsiveUtils.isTablet(context) ? 2 : 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: AdminTheme.spacingMd,
              mainAxisSpacing: AdminTheme.spacingMd,
            ),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index]);
            },
          );
        }
      },
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingLg),
        child: content,
      ),
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
                  Text(
                    transaction.description.isNotEmpty
                        ? transaction.description
                        : transaction.type.toUpperCase(),
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM d, y • h:mm a',
                    ).format(transaction.createdAt),
                    style: const TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
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
                Text(
                  currencyFormat.format(transaction.amount),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
