import 'package:flutter/material.dart';

import '../../admin/withdrawal_requests_screen.dart';

class WithdrawalsModule extends StatelessWidget {
  const WithdrawalsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const WithdrawalRequestsScreen(isEmbedded: true);
  }
}

