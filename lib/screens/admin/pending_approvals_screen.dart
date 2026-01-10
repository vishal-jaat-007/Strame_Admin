import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../services/creator_service.dart';
import '../../models/creator.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_button.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../../widgets/common/user_avatar.dart';
import 'package:intl/intl.dart';

class PendingApprovalsScreen extends StatefulWidget {
  final bool isEmbedded;

  const PendingApprovalsScreen({super.key, this.isEmbedded = false});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final CreatorService _creatorService = CreatorService();

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<Creator>>(
      stream: _creatorService.getPendingCreators(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(
            '❌ [PendingApprovalsScreen] Error loading requests: ${snapshot.error}',
          );
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: AdminTheme.errorRed),
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

        final creators = snapshot.data!;

        if (creators.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AdminTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AdminTheme.spacingMd),
                Text(
                  'No pending approvals',
                  style: AdminTheme.headlineSmall.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

        return GridView.builder(
          padding: const EdgeInsets.all(AdminTheme.spacingLg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : (screenWidth < 1100 ? 2 : 3),
            childAspectRatio:
                isMobile
                    ? 1.2
                    : (screenWidth < 900
                        ? 0.7 // Taller for narrow tablet
                        : (screenWidth < 1200 ? 0.85 : 0.95)),
            crossAxisSpacing: AdminTheme.spacingMd,
            mainAxisSpacing: AdminTheme.spacingMd,
          ),
          itemCount: creators.length,
          itemBuilder: (context, index) {
            return _buildCreatorCard(context, creators[index]);
          },
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AdminTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pending Approvals',
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
      body: content,
    );
  }

  Widget _buildCreatorCard(BuildContext context, Creator creator) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar & Name
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
                      Text(
                        creator.displayName,
                        style: AdminTheme.headlineSmall.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        creator.category,
                        style: AdminTheme.labelSmall.copyWith(
                          color: AdminTheme.electricBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTheme.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
                    border: Border.all(
                      color: AdminTheme.warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Pending',
                    style: AdminTheme.labelSmall.copyWith(
                      color: AdminTheme.warningOrange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.spacingMd),
            const Divider(color: AdminTheme.borderColor),
            const SizedBox(height: AdminTheme.spacingMd),

            // Details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Joined',
                      DateFormat('MMM d, y').format(creator.createdAt),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.language,
                      'Languages',
                      creator.languages.join(', '),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      creator.location ?? 'Unknown',
                    ),
                    const SizedBox(height: 12),
                    Text('Bio', style: AdminTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      creator.bio.isNotEmpty ? creator.bio : 'No bio provided',
                      style: AdminTheme.bodySmall.copyWith(
                        color: AdminTheme.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AdminTheme.spacingMd),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context, creator),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.errorRed,
                      side: const BorderSide(color: AdminTheme.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm,
                        ),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Reject'),
                    ),
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingSm),
                Expanded(
                  child: AnimatedButton(
                    onPressed: () => _handleApprove(context, creator),
                    backgroundColor: AdminTheme.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 40),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Approve',
                        style: TextStyle(
                          color: AdminTheme.backgroundPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AdminTheme.textTertiary),
        const SizedBox(width: 8),
        Text('$label: ', style: AdminTheme.labelSmall),
        Expanded(
          child: Text(
            value,
            style: AdminTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove(BuildContext context, Creator creator) async {
    try {
      await _creatorService.approveCreator(creator.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${creator.displayName} approved successfully'),
            backgroundColor: AdminTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving creator: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, Creator creator) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'Reject Creator?',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: Text(
              'Are you sure you want to reject ${creator.displayName}? This action cannot be undone.',
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AdminTheme.errorRed,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _creatorService.rejectCreator(creator.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creator request rejected'),
              backgroundColor: AdminTheme.textPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting creator: $e'),
              backgroundColor: AdminTheme.errorRed,
            ),
          );
        }
      }
    }
  }
}
