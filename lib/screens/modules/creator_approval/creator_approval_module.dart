import 'package:flutter/material.dart';

import '../../admin/pending_approvals_screen.dart';

class CreatorApprovalModule extends StatelessWidget {
  const CreatorApprovalModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const PendingApprovalsScreen(isEmbedded: true);
  }
}



