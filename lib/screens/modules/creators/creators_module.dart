import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../admin/pending_approvals_screen.dart';
import '../../../../theme/admin_theme.dart';
import '../../../../services/creator_service.dart';
import '../../../../models/creator.dart';
import '../../../../widgets/common/glass_card.dart';
import '../../../../widgets/common/animated_button.dart';
import '../../../../widgets/common/user_avatar.dart';
import '../../../../utils/responsive_utils.dart' as app_utils;

class CreatorsModule extends StatefulWidget {
  const CreatorsModule({super.key});

  @override
  State<CreatorsModule> createState() => _CreatorsModuleState();
}

class _CreatorsModuleState extends State<CreatorsModule> {
  final CreatorService _creatorService = CreatorService();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Pending, Blocked
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Creator>>(
      stream: _creatorService.getAllCreators(),
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

        var creators =
            snapshot.data!
                .where((c) => c.displayName.isNotEmpty && c.uid.isNotEmpty)
                .toList();

        // Sort by createdAt descending (client-side)
        creators.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          creators =
              creators.where((creator) {
                final query = _searchQuery.toLowerCase();
                return creator.displayName.toLowerCase().contains(query) ||
                    creator.category.toLowerCase().contains(query);
              }).toList();
        }

        if (_statusFilter != 'All') {
          creators =
              creators.where((creator) {
                if (_statusFilter == 'Blocked') return creator.isBlocked;
                if (_statusFilter == 'Active')
                  return creator.isApproved && !creator.isBlocked;
                if (_statusFilter == 'Pending') return !creator.isApproved;
                return true;
              }).toList();
        }

        if (_categoryFilter != 'All') {
          creators =
              creators
                  .where((creator) => creator.category == _categoryFilter)
                  .toList();
        }

        // Calculate stats
        final totalCreators = creators.length;
        final onlineCreators = creators.where((c) => c.isOnline).length;
        final pendingCreators = creators.where((c) => !c.isApproved).length;
        final blockedCreators = creators.where((c) => c.isBlocked).length;

        // Extract unique categories for filter
        final categories = [
          'All',
          ...{...creators.map((c) => c.category).where((c) => c.isNotEmpty)},
        ];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Creator Management',
                style: AdminTheme.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AdminTheme.spacingLg),

              // Stats Cards
              _buildStatsCards(
                context,
                totalCreators,
                onlineCreators,
                pendingCreators,
                blockedCreators,
              ),

              const SizedBox(height: AdminTheme.spacingLg),

              // Search & Filter
              _buildToolbar(context, categories),

              const SizedBox(height: AdminTheme.spacingMd),

              // Creator List
              creators.isEmpty
                  ? _buildEmptyState()
                  : _buildCreatorList(context, creators),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    int total,
    int online,
    int pending,
    int blocked,
  ) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    final cards = [
      _buildStatCard(
        'Total Creators',
        total.toString(),
        Icons.star,
        AdminTheme.primaryPurple,
      ),
      _buildStatCard(
        'Online Creators',
        online.toString(),
        Icons.fiber_manual_record,
        AdminTheme.successGreen,
      ),
      _buildStatCard(
        'Pending Approval',
        pending.toString(),
        Icons.pending_actions,
        AdminTheme.warningYellow,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const Scaffold(
                    backgroundColor: AdminTheme.backgroundPrimary,
                    body: SafeArea(child: PendingApprovalsScreen()),
                  ),
            ),
          );
        },
      ),
      _buildStatCard(
        'Blocked',
        blocked.toString(),
        Icons.block,
        AdminTheme.errorRed,
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder:
              (context, index) => const SizedBox(width: AdminTheme.spacingMd),
          itemBuilder:
              (context, index) => SizedBox(width: 160, child: cards[index]),
        ),
      );
    }

    return Row(
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
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
            Text(
              value,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, List<String> categories) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Wrap(
        spacing: AdminTheme.spacingMd,
        runSpacing: AdminTheme.spacingMd,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              style: const TextStyle(color: AdminTheme.textPrimary),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search creators...',
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

          // Status Filter
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
                    ['All', 'Active', 'Pending', 'Blocked'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
            ),
          ),

          // Category Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AdminTheme.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categoryFilter,
                dropdownColor: AdminTheme.cardDark,
                style: const TextStyle(color: AdminTheme.textPrimary),
                icon: const Icon(
                  Icons.category,
                  color: AdminTheme.textSecondary,
                ),
                items:
                    categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.isEmpty ? 'Uncategorized' : cat),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _categoryFilter = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorList(BuildContext context, List<Creator> creators) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: creators.length,
        separatorBuilder:
            (context, index) => const SizedBox(height: AdminTheme.spacingMd),
        itemBuilder: (context, index) => _buildCreatorCard(creators[index]),
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
            horizontalMargin: AdminTheme.spacingLg,
            columnSpacing: AdminTheme.spacingXl,
            columns: const [
              DataColumn(label: Text('Creator', style: _headerStyle)),
              DataColumn(label: Text('Category', style: _headerStyle)),
              DataColumn(label: Text('Status', style: _headerStyle)),
              DataColumn(label: Text('Earnings', style: _headerStyle)),
              DataColumn(label: Text('Joined', style: _headerStyle)),
              DataColumn(label: Text('Actions', style: _headerStyle)),
            ],
            rows: creators.map((creator) => _buildDataRow(creator)).toList(),
          ),
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: AdminTheme.textSecondary,
    fontWeight: FontWeight.bold,
  );

  DataRow _buildDataRow(Creator creator) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Stack(
                children: [
                  UserAvatar(
                    photoUrl: creator.photoUrl,
                    name: creator.displayName,
                    radius: 16,
                  ),
                  if (creator.isOnline)
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    creator.displayName,
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (creator.isFeatured)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          fontSize: 8,
                          color: AdminTheme.accentBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            creator.category,
            style: const TextStyle(color: AdminTheme.textSecondary),
          ),
        ),
        DataCell(_buildStatusBadge(creator)),
        DataCell(
          Text(
            '\$${creator.totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(color: AdminTheme.successGreen),
          ),
        ),
        DataCell(
          Text(
            DateFormat('MMM d, y').format(creator.createdAt),
            style: const TextStyle(color: AdminTheme.textSecondary),
          ),
        ),
        DataCell(_buildActions(creator)),
      ],
    );
  }

  Widget _buildStatusBadge(Creator creator) {
    Color color;
    String text;

    if (creator.isBlocked) {
      color = AdminTheme.errorRed;
      text = 'BLOCKED';
    } else if (!creator.isApproved) {
      color = AdminTheme.warningYellow;
      text = 'PENDING';
    } else if (creator.isOnline) {
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
  }

  Widget _buildActions(Creator creator) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            creator.isBlocked ? Icons.lock_open : Icons.block,
            color:
                creator.isBlocked
                    ? AdminTheme.successGreen
                    : AdminTheme.errorRed,
            size: 20,
          ),
          tooltip: creator.isBlocked ? 'Unblock' : 'Block',
          onPressed: () => _toggleBlockStatus(creator),
        ),
        if (!creator.isApproved)
          IconButton(
            icon: const Icon(
              Icons.check_circle,
              color: AdminTheme.successGreen,
              size: 20,
            ),
            tooltip: 'Approve',
            onPressed: () => _approveCreator(creator),
          ),
      ],
    );
  }

  Widget _buildCreatorCard(Creator creator) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  UserAvatar(
                    photoUrl: creator.photoUrl,
                    name: creator.displayName,
                    radius: 24,
                    fontSize: 18,
                  ),
                  if (creator.isOnline)
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
                      creator.displayName,
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      creator.category,
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(creator),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earnings',
                    style: TextStyle(
                      color: AdminTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '\$${creator.totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AdminTheme.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Joined',
                    style: TextStyle(
                      color: AdminTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, y').format(creator.createdAt),
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!creator.isApproved || !creator.isBlocked)
            Padding(
              padding: const EdgeInsets.only(top: AdminTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!creator.isApproved)
                    TextButton.icon(
                      onPressed: () => _approveCreator(creator),
                      icon: const Icon(
                        Icons.check,
                        color: AdminTheme.successGreen,
                        size: 16,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: AdminTheme.successGreen),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _toggleBlockStatus(creator),
                    icon: Icon(
                      creator.isBlocked ? Icons.lock_open : Icons.block,
                      color:
                          creator.isBlocked
                              ? AdminTheme.successGreen
                              : AdminTheme.errorRed,
                      size: 16,
                    ),
                    label: Text(
                      creator.isBlocked ? 'Unblock' : 'Block',
                      style: TextStyle(
                        color:
                            creator.isBlocked
                                ? AdminTheme.successGreen
                                : AdminTheme.errorRed,
                      ),
                    ),
                  ),
                ],
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
            Icons.group_off,
            size: 64,
            color: AdminTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Text(
            'No creators found',
            style: AdminTheme.headlineSmall.copyWith(
              color: AdminTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlockStatus(Creator creator) async {
    final action = creator.isBlocked ? 'unblock' : 'block';
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
              'Are you sure you want to $action ${creator.displayName}?',
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
                    creator.isBlocked
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
      if (creator.isBlocked) {
        await _creatorService.unblockCreator(creator.uid);
      } else {
        await _creatorService.blockCreator(creator.uid);
      }
    }
  }

  Future<void> _approveCreator(Creator creator) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'Confirm Approval',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: Text(
              'Approve ${creator.displayName} as a creator?',
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
                  'APPROVE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _creatorService.approveCreator(creator.uid);
    }
  }
}

