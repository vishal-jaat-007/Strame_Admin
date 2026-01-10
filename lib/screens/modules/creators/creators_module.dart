import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<Creator> _creators = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCreators();
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
      _loadCreators();
    }
  }

  Future<void> _loadCreators({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _creators.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _creatorService.getCreatorsPaginated(
        limit: 20,
        startAfter: _lastDocument,
        isApproved:
            _statusFilter == 'Pending'
                ? false
                : (_statusFilter == 'Active' ? true : null),
      );

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newCreators =
          snapshot.docs
              .map(
                (doc) =>
                    Creator.fromFirestore(doc.data() as Map<String, dynamic>),
              )
              .toList();

      setState(() {
        _creators.addAll(newCreators);
        _lastDocument = snapshot.docs.last;
        _isLoading = false;
        if (newCreators.length < 20) _hasMore = false;
      });
    } catch (e) {
      debugPrint('Error loading creators: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading creators: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Client-side filtering for search and specific status/category
    var filteredCreators =
        _creators.where((c) {
          // Hide empty/anonymous profiles that have no data (clutter)
          if (c.displayName == 'Anonymous' && c.category.isEmpty) return false;
          return true;
        }).toList();
    if (_searchQuery.isNotEmpty) {
      filteredCreators =
          filteredCreators.where((c) {
            final query = _searchQuery.toLowerCase();
            return c.displayName.toLowerCase().contains(query) ||
                c.category.toLowerCase().contains(query);
          }).toList();
    }

    if (_categoryFilter != 'All') {
      filteredCreators =
          filteredCreators.where((c) => c.category == _categoryFilter).toList();
    }

    if (_statusFilter == 'Blocked') {
      filteredCreators = filteredCreators.where((c) => c.isBlocked).toList();
    }

    final categories = [
      'All',
      ...{..._creators.map((c) => c.category).where((c) => c.isNotEmpty)},
    ];

    return Column(
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

        // Search & Filter
        _buildToolbar(context, categories),

        const SizedBox(height: AdminTheme.spacingMd),

        // Creator List
        Expanded(
          child:
              filteredCreators.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView(
                    controller: _scrollController,
                    children: [
                      _buildCreatorList(context, filteredCreators),

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
                            onPressed: _loadCreators,
                            child: const Text('Load More'),
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
        ),
      ],
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
              onChanged: (value) {
                _searchQuery = value;
                setState(() {});
              },
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
                onChanged: (value) {
                  setState(() => _statusFilter = value!);
                  _loadCreators(refresh: true);
                },
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
                  Icons.category_rounded,
                  color: AdminTheme.textSecondary,
                ),
                items:
                    categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                onChanged: (value) => setState(() => _categoryFilter = value!),
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
            Icons.person_off_rounded,
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
            headingRowColor: WidgetStateProperty.all(
              AdminTheme.backgroundSecondary.withOpacity(0.5),
            ),
            dataRowColor: WidgetStateProperty.all(Colors.transparent),
            dividerThickness: 0.5,
            columns: const [
              DataColumn(
                label: Text(
                  'Creator',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              DataColumn(
                label: Text(
                  'Category',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              DataColumn(
                label: Text(
                  'Earnings',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              DataColumn(
                label: Text(
                  'Calls/Mins',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              DataColumn(
                label: Text(
                  'Rating',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
            ],
            rows: creators.map((c) => _buildDataRow(c)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Creator creator) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              UserAvatar(
                photoUrl: creator.photoUrl,
                name: creator.displayName,
                radius: 16,
              ),
              const SizedBox(width: 8),
              Text(
                creator.displayName,
                style: const TextStyle(color: AdminTheme.textPrimary),
              ),
              if (creator.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Colors.blue, size: 16),
              ],
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                creator.category.isNotEmpty ? creator.category : 'N/A',
                style: const TextStyle(color: AdminTheme.textSecondary),
              ),
              if (creator.displayName == 'Anonymous' && creator.uid.isNotEmpty)
                Text(
                  'ID: ${creator.uid.length > 6 ? creator.uid.substring(0, 6) : creator.uid}...',
                  style: const TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            '\$${creator.totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(color: AdminTheme.successGreen),
          ),
        ),
        DataCell(
          Text(
            '${creator.totalCalls}/${creator.totalLiveMinutes}m',
            style: const TextStyle(color: AdminTheme.textTertiary),
          ),
        ),
        DataCell(
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                creator.rating.toStringAsFixed(1),
                style: const TextStyle(color: AdminTheme.textPrimary),
              ),
            ],
          ),
        ),
        DataCell(_buildStatusBadge(creator)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AdminTheme.textSecondary),
                onPressed: () => _showEditCreatorDialog(creator),
                tooltip: 'Edit Settings',
              ),
              if (!creator.isApproved)
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AdminTheme.successGreen,
                  ),
                  onPressed: () => _approveCreator(creator),
                  tooltip: 'Approve',
                ),
              IconButton(
                icon: Icon(
                  creator.isBlocked
                      ? Icons.lock_open_rounded
                      : Icons.block_flipped,
                  color:
                      creator.isBlocked
                          ? AdminTheme.successGreen
                          : AdminTheme.errorRed,
                ),
                onPressed: () => _toggleBlockStatus(creator),
                tooltip: creator.isBlocked ? 'Unblock' : 'Block',
              ),
            ],
          ),
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
              UserAvatar(
                photoUrl: creator.photoUrl,
                name: creator.displayName,
                radius: 24,
              ),
              const SizedBox(width: AdminTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            creator.displayName,
                            style: AdminTheme.headlineSmall.copyWith(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (creator.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      creator.category,
                      style: AdminTheme.bodySmall.copyWith(
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(creator),
            ],
          ),
          const Divider(height: AdminTheme.spacingLg, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${creator.totalEarnings.toStringAsFixed(0)} | ${creator.totalCalls} calls',
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AdminTheme.textSecondary,
                    ),
                    onPressed: () => _showEditCreatorDialog(creator),
                  ),
                  if (!creator.isApproved)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: AdminTheme.successGreen,
                      ),
                      onPressed: () => _approveCreator(creator),
                    ),
                  IconButton(
                    icon: Icon(
                      creator.isBlocked
                          ? Icons.lock_open_rounded
                          : Icons.block_flipped,
                      color:
                          creator.isBlocked
                              ? AdminTheme.successGreen
                              : AdminTheme.errorRed,
                    ),
                    onPressed: () => _toggleBlockStatus(creator),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Creator creator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: creator.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: creator.statusColor.withOpacity(0.3)),
      ),
      child: Text(
        creator.statusText.toUpperCase(),
        style: TextStyle(
          color: creator.statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
      try {
        if (creator.isBlocked) {
          await _creatorService.unblockCreator(creator.uid);
        } else {
          await _creatorService.blockCreator(creator.uid);
        }
        if (mounted) {
          setState(() {
            final index = _creators.indexWhere((c) => c.uid == creator.uid);
            if (index != -1) {
              _creators[index] = creator.copyWith(
                isBlocked: !creator.isBlocked,
              );
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Creator ${action}ed successfully'),
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

  Future<void> _approveCreator(Creator creator) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'Approve Creator',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: Text(
              'Are you sure you want to approve ${creator.displayName}?',
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
      try {
        await _creatorService.approveCreator(creator.uid);
        if (mounted) {
          setState(() {
            final index = _creators.indexWhere((c) => c.uid == creator.uid);
            if (index != -1) {
              _creators[index] = creator.copyWith(isApproved: true);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creator approved successfully'),
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

  void _showEditCreatorDialog(Creator creator) {
    bool isVerified = creator.isVerified;
    final voiceRateController = TextEditingController(
      text: creator.customVoiceRate?.toString() ?? '',
    );
    final videoRateController = TextEditingController(
      text: creator.customVideoRate?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AdminTheme.cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AdminTheme.textSecondary.withOpacity(0.2),
                  ),
                ),
                title: Text(
                  'Edit Creator: ${creator.displayName}',
                  style: const TextStyle(color: AdminTheme.textPrimary),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Verified Creator',
                            style: TextStyle(color: AdminTheme.textSecondary),
                          ),
                          Switch(
                            value: isVerified,
                            onChanged: (val) {
                              setDialogState(() => isVerified = val);
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      const Text(
                        'Custom Rates (Coins/min)',
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Leave empty to use global rates.',
                        style: TextStyle(
                          color: AdminTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: voiceRateController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Voice Call Rate',
                          labelStyle: const TextStyle(
                            color: AdminTheme.textSecondary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AdminTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: videoRateController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Video Call Rate',
                          labelStyle: const TextStyle(
                            color: AdminTheme.textSecondary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AdminTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final voiceRate = int.tryParse(voiceRateController.text);
                      final videoRate = int.tryParse(videoRateController.text);

                      try {
                        await _creatorService.updateCreatorSettings(
                          creator.uid,
                          isVerified: isVerified,
                          customVoiceRate: voiceRate,
                          customVideoRate: videoRate,
                        );

                        if (mounted) {
                          setState(() {
                            final index = _creators.indexWhere(
                              (c) => c.uid == creator.uid,
                            );
                            if (index != -1) {
                              _creators[index] = creator.copyWith(
                                isVerified: isVerified,
                                customVoiceRate: voiceRate,
                                customVideoRate: videoRate,
                              );
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Creator settings updated'),
                              backgroundColor: AdminTheme.successGreen,
                            ),
                          );
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error updating creator: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryPurple,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
