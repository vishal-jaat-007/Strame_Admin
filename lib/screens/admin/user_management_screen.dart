import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<AppUser> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
      _loadUsers();
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _users.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _userService.getUsersPaginated(
        limit: 20,
        startAfter: _lastDocument,
        searchQuery: _searchQuery,
      );

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newUsers =
          snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data()))
              .toList();

      setState(() {
        _users.addAll(newUsers);
        _lastDocument = snapshot.docs.last;
        _isLoading = false;
        if (newUsers.length < 20) _hasMore = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply client-side filters on the already loaded paginated list
    var filteredUsers = _users;
    if (_statusFilter != 'All') {
      filteredUsers =
          filteredUsers.where((user) {
            if (_statusFilter == 'Blocked') return user.isBlocked;
            if (_statusFilter == 'Active') return !user.isBlocked;
            return true;
          }).toList();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter
        _buildToolbar(context),

        const SizedBox(height: AdminTheme.spacingMd),

        // User List
        Expanded(
          child:
              filteredUsers.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView(
                    controller: _scrollController,
                    children: [
                      // User List
                      _buildUserList(context, filteredUsers),

                      // Loading indicator at bottom
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AdminTheme.spacingMd),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      // Load more button (fallback)
                      if (_hasMore && !_isLoading)
                        Center(
                          child: TextButton(
                            onPressed: _loadUsers,
                            child: const Text('Load More'),
                          ),
                        ),
                      const SizedBox(height: 100), // Bottom padding
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

  Widget _buildToolbar(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: AdminTheme.textPrimary),
              onChanged: (value) {
                _searchQuery = value;
                _loadUsers(refresh: true);
              },
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
    if (app_utils.AppResponsiveUtils.isMobile(context)) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder:
            (context, index) => const SizedBox(height: AdminTheme.spacingMd),
        itemBuilder: (context, index) => _buildUserCard(users[index]),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return GlassCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 64,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AdminTheme.backgroundSecondary.withOpacity(0.5),
            ),
            dataRowColor: WidgetStateProperty.all(Colors.transparent),
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
                  'Coins',
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
                  'Status',
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
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(photoUrl: user.photoUrl, name: user.name, radius: 16),
              const SizedBox(width: 8),
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
        DataCell(_buildRoleBadge(user.role)),
        DataCell(
          Text(
            user.coins.toString(),
            style: const TextStyle(
              color: AdminTheme.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Text(
            DateFormat('MMM d, yyyy').format(user.createdAt),
            style: const TextStyle(
              color: AdminTheme.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(user.isBlocked)),
        DataCell(
          IconButton(
            icon: Icon(
              user.isBlocked ? Icons.lock_open_rounded : Icons.block_flipped,
              color:
                  user.isBlocked
                      ? AdminTheme.successGreen
                      : AdminTheme.errorRed,
              size: 20,
            ),
            onPressed: () => _toggleBlockStatus(user),
            tooltip: user.isBlocked ? 'Unblock User' : 'Block User',
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
              UserAvatar(photoUrl: user.photoUrl, name: user.name, radius: 24),
              const SizedBox(width: AdminTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AdminTheme.headlineSmall.copyWith(fontSize: 16),
                    ),
                    Text(
                      user.email,
                      style: AdminTheme.bodySmall.copyWith(
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRoleBadge(user.role),
            ],
          ),
          const Divider(height: AdminTheme.spacingLg, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coins: ${user.coins}',
                    style: TextStyle(
                      color: AdminTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Joined: ${DateFormat('MMM d').format(user.createdAt)}',
                    style: AdminTheme.labelSmall,
                  ),
                ],
              ),
              Row(
                children: [
                  _buildStatusBadge(user.isBlocked),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      user.isBlocked
                          ? Icons.lock_open_rounded
                          : Icons.block_flipped,
                      color:
                          user.isBlocked
                              ? AdminTheme.successGreen
                              : AdminTheme.errorRed,
                    ),
                    onPressed: () => _toggleBlockStatus(user),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = AdminTheme.errorRed;
        break;
      case 'creator':
        color = AdminTheme.primaryPurple;
        break;
      default:
        color = AdminTheme.secondaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isBlocked) {
    final color = isBlocked ? AdminTheme.errorRed : AdminTheme.successGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isBlocked ? 'BLOCKED' : 'ACTIVE',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
          setState(() {
            final index = _users.indexWhere((u) => u.uid == user.uid);
            if (index != -1) {
              _users[index] = user.copyWith(isBlocked: !user.isBlocked);
            }
          });
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
