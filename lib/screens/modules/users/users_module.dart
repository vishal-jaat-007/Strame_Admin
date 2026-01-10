import 'package:flutter/material.dart';
import '../../admin/user_management_screen.dart';

class UsersModule extends StatelessWidget {
  const UsersModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserManagementScreen(isEmbedded: true);
  }
}



