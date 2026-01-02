import 'package:flutter/material.dart';
import '../../admin/transactions_screen.dart';

class TransactionsModule extends StatelessWidget {
  const TransactionsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionsScreen(isEmbedded: true);
  }
}

