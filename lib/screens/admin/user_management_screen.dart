import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_theme.dart';
import '../../services/user_service.dart';
import '../../models/app_user.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_button.dart';
import '../../widgets/common/user_avatar.dart';
import '../../utils/responsive_utils.dart' as app_utils;

class UserManagementScreen extends StatefulWidget {
  final bool isEmbedded;

  const UserManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Blocked

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<AppUser>>(
      stream: _userService.getAllUsers(),
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

        var users = snapshot.data!;

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          users =
              users.where((user) {
                final query = _searchQuery.toLowerCase();
                return user.name.toLowerCase().contains(query) ||
                    user.email.toLowerCase().contains(query);
              }).toList();
        }

        if (_statusFilter != 'All') {
          users =
              users.where((user) {
                if (_statusFilter == 'Blocked') return user.isBlocked;
                if (_statusFilter == 'Active') return !user.isBlocked;
                return true;
              }).toList();
        }

        // Calculate stats
        final totalUsers = users.length;
        final onlineUsers = users.where((u) => u.isOnline).length;
        final blockedUsers = users.where((u) => u.isBlocked).length;
        final newUsersToday =
            users.where((u) {
              final now = DateTime.now();
              return u.createdAt.year == now.year &&
                  u.createdAt.month == now.month &&
                  u.createdAt.day == now.day;
            }).length;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsCards(
                context,
                totalUsers,
                onlineUsers,
                blockedUsers,
                newUsersToday,
              ),

              const SizedBox(height: AdminTheme.spacingLg),

              // Search & Filter
              _buildToolbar(context),

              const SizedBox(height: AdminTheme.spacingMd),

              // User List
              users.isEmpty
                  ? _buildEmptyState()
                  : _buildUserList(context, users),
            ],
          ),
        );
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
          'User Management',
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

  Widget _buildStatsCards(
    BuildContext context,
    int total,
    int active,
    int blocked,
    int newToday,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    final cards = [
      _buildStatCard(
        'Total Users',
        total.toString(),
        Icons.people,
        AdminTheme.primaryPurple,
      ),
      _buildStatCard(
        'Active Users',
        active.toString(),
        Icons.check_circle,
        AdminTheme.successGreen,
      ),
      _buildStatCard(
        'Blocked Users',
        blocked.toString(),
        Icons.block,
        AdminTheme.errorRed,
      ),
      _buildStatCard(
        'New Today',
        newToday.toString(),
        Icons.person_add,
        AdminTheme.accentBlue,
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 150, // Increased height to prevent vertical overflow
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: cards.length,
          separatorBuilder:
              (context, index) => const SizedBox(width: AdminTheme.spacingMd),
          itemBuilder:
              (context, index) => SizedBox(width: 170, child: cards[index]),
        ),
      );
    }

    // Desktop/Tablet: Use Grid for smaller desktop widths, Row for larger
    if (screenWidth < 1100) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.9, // Reduced from 2.2 to make cards taller
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: cards,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            cards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: card,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: AdminTheme.textPrimary),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: AdminTheme.textTertiary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AdminTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AdminTheme.backgroundSecondary.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AdminTheme.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                dropdownColor: AdminTheme.cardDark,
                style: const TextStyle(color: AdminTheme.textPrimary),
                icon: const Icon(
                  Icons.filter_list,
                  color: AdminTheme.textSecondary,
                ),
                items:
                    ['All', 'Active', 'Blocked'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: AdminTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Text(
            'No users found',
            style: AdminTheme.headlineSmall.copyWith(
              color: AdminTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<AppUser> users) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder:
            (context, index) => const SizedBox(height: AdminTheme.spacingMd),
        itemBuilder: (context, index) => _buildUserCard(users[index]),
      );
    }

    return GlassCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 64,
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AdminTheme.backgroundSecondary.withOpacity(0.5),
            ),
            dataRowColor: MaterialStateProperty.all(Colors.transparent),
            dividerThickness: 0.5,
            horizontalMargin: screenWidth < 1000 ? 8 : AdminTheme.spacingLg,
            columnSpacing: screenWidth < 1000 ? 12 : AdminTheme.spacingLg,
            columns: const [
              DataColumn(
                label: Text(
                  'User',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Email',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Role',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Joined',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: users.map((user) => _buildDataRow(user)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(AppUser user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Stack(
                children: [
                  UserAvatar(
                    photoUrl: user.photoUrl,
                    name: user.name,
                    radius: 16,
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AdminTheme.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AdminTheme.cardDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Text(
                user.name,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            user.email,
            style: const TextStyle(color: AdminTheme.textSecondary),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (user.isCreator
                      ? AdminTheme.accentBlue
                      : AdminTheme.textTertiary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                color:
                    user.isCreator
                        ? AdminTheme.accentBlue
                        : AdminTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Builder(
            builder: (context) {
              Color color;
              String text;
              if (user.isBlocked) {
                color = AdminTheme.errorRed;
                text = 'BLOCKED';
              } else if (user.isOnline) {
                color = AdminTheme.successGreen;
                text = 'ONLINE';
              } else {
                color = AdminTheme.textTertiary;
                text = 'OFFLINE';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        DataCell(
          Text(
            DateFormat('MMM d, y').format(user.createdAt),
            style: const TextStyle(color: AdminTheme.textSecondary),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(
                  user.isBlocked ? Icons.lock_open : Icons.block,
                  color:
                      user.isBlocked
                          ? AdminTheme.successGreen
                          : AdminTheme.errorRed,
                  size: 20,
                ),
                tooltip: user.isBlocked ? 'Unblock User' : 'Block User',
                onPressed: () => _toggleBlockStatus(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AppUser user) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  UserAvatar(
                    photoUrl: user.photoUrl,
                    name: user.name,
                    radius: 24,
                    fontSize: 18,
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AdminTheme.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AdminTheme.cardDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AdminTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Slightly smaller for narrow screens
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Builder(
                builder: (context) {
                  Color color;
                  String text;
                  if (user.isBlocked) {
                    color = AdminTheme.errorRed;
                    text = 'BLOCKED';
                  } else if (user.isOnline) {
                    color = AdminTheme.successGreen;
                    text = 'ONLINE';
                  } else {
                    color = AdminTheme.textTertiary;
                    text = 'OFFLINE';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Joined: ${DateFormat('MMM d, y').format(user.createdAt)}',
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Role: ${user.role.toUpperCase()}',
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          const Divider(color: AdminTheme.borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _toggleBlockStatus(user),
                icon: Icon(
                  user.isBlocked ? Icons.lock_open : Icons.block,
                  color:
                      user.isBlocked
                          ? AdminTheme.successGreen
                          : AdminTheme.errorRed,
                  size: 18,
                ),
                label: Text(
                  user.isBlocked ? 'Unblock' : 'Block',
                  style: TextStyle(
                    color:
                        user.isBlocked
                            ? AdminTheme.successGreen
                            : AdminTheme.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlockStatus(AppUser user) async {
    final action = user.isBlocked ? 'unblock' : 'block';
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: Text(
              'Confirm $action',
              style: const TextStyle(color: AdminTheme.textPrimary),
            ),
            content: Text(
              'Are you sure you want to $action ${user.name}?',
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              AnimatedButton(
                onPressed: () => Navigator.pop(context, true),
                backgroundColor:
                    user.isBlocked
                        ? AdminTheme.successGreen
                        : AdminTheme.errorRed,
                child: Text(
                  action.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        if (user.isBlocked) {
          await _userService.unblockUser(user.uid);
        } else {
          await _userService.blockUser(user.uid);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${action}ed successfully'),
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
}
