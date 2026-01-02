import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/admin_theme.dart';
import '../../../../services/call_service.dart';
import '../../../../models/call_session.dart';
import '../../../../widgets/common/glass_card.dart';
import '../../../../widgets/common/user_avatar.dart';
import '../../../../utils/responsive_utils.dart' as app_utils;

class CallsModule extends StatefulWidget {
  const CallsModule({super.key});

  @override
  State<CallsModule> createState() => _CallsModuleState();
}

class _CallsModuleState extends State<CallsModule> {
  final CallService _callService = CallService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallSession>>(
      stream: _callService.getActiveCalls(),
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

        final calls = snapshot.data!;
        final activeVoice = calls.where((c) => c.isVoice).length;
        final activeVideo = calls.where((c) => c.isVideo).length;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Call Monitoring',
                style: AdminTheme.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AdminTheme.spacingLg),

              // Stats
              _buildStatsCards(context, calls.length, activeVoice, activeVideo),

              const SizedBox(height: AdminTheme.spacingXl),

              // Active Calls Section
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AdminTheme.successGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AdminTheme.successGreen,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AdminTheme.spacingSm),
                  Text('Live Sessions', style: AdminTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: AdminTheme.spacingMd),

              if (calls.isEmpty)
                _buildEmptyState()
              else
                _buildCallsGrid(context, calls),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    int total,
    int voice,
    int video,
  ) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);
    final cards = [
      _buildStatCard(
        'Active Calls',
        total.toString(),
        Icons.phone_in_talk,
        AdminTheme.primaryPurple,
      ),
      _buildStatCard(
        'Voice Calls',
        voice.toString(),
        Icons.mic,
        AdminTheme.accentBlue,
      ),
      _buildStatCard(
        'Video Calls',
        video.toString(),
        Icons.videocam,
        AdminTheme.secondaryPink,
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 110,
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
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
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
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AdminTheme.spacingXl),
              decoration: BoxDecoration(
                color: AdminTheme.cardDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AdminTheme.borderColor.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.call_end_outlined,
                size: 48,
                color: AdminTheme.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AdminTheme.spacingMd),
            Text(
              'No Active Calls',
              style: AdminTheme.headlineSmall.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time voice and video calls will appear here.',
              style: TextStyle(color: AdminTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsGrid(BuildContext context, List<CallSession> calls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            app_utils.AppResponsiveUtils.isMobile(context)
                ? 1
                : app_utils.AppResponsiveUtils.isTablet(context)
                ? 2
                : 3,
        childAspectRatio: 1.4, // Card aspect ratio
        crossAxisSpacing: AdminTheme.spacingMd,
        mainAxisSpacing: AdminTheme.spacingMd,
      ),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        return _CallCard(call: calls[index]);
      },
    );
  }
}

class _CallCard extends StatefulWidget {
  final CallSession call;

  const _CallCard({required this.call});

  @override
  State<_CallCard> createState() => _CallCardState();
}

class _CallCardState extends State<_CallCard> {
  // Simple fetchers for demo; specialized services would be better
  Future<Map<String, dynamic>?> _fetchUser(
    String uid,
    String collection,
  ) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(uid)
              .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.call.isVideo ? AdminTheme.secondaryPink : AdminTheme.accentBlue;

    return GlassCard(
      borderColor: borderColor.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        child: Column(
          children: [
            // Header: Type & Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
                    border: Border.all(color: borderColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.call.isVideo ? Icons.videocam : Icons.mic,
                        size: 14,
                        color: borderColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.call.type.toUpperCase(),
                        style: TextStyle(
                          color: borderColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _DurationTimer(startTime: widget.call.createdAt),
              ],
            ),

            const Spacer(),

            // Participants Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Caller (User)
                Expanded(
                  child: _buildParticipant(
                    widget.call.callerId,
                    'users',
                    'Caller',
                    alignLeft: true,
                  ),
                ),

                // Connection Animation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.graphic_eq, // Sound wave icon
                    color: AdminTheme.textSecondary.withOpacity(0.5),
                  ),
                ),

                // Receiver (Creator)
                Expanded(
                  child: _buildParticipant(
                    widget.call.creatorId,
                    'creators',
                    'Creator',
                    alignLeft: false,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () => _handleEndCall(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.errorRed,
                  side: const BorderSide(color: AdminTheme.errorRed),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('End Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipant(
    String uid,
    String collection,
    String label, {
    required bool alignLeft,
  }) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(uid, collection),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name =
            data != null
                ? (data['name'] ?? data['displayName'] ?? 'Unknown')
                : 'Loading...';
        final photoUrl = data?['photoUrl'];

        return Column(
          children: [
            UserAvatar(photoUrl: photoUrl, name: name, radius: 20),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            Text(
              label,
              style: const TextStyle(
                color: AdminTheme.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleEndCall(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'End Call?',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: const Text(
              'Are you sure you want to force end this session?',
              style: TextStyle(color: AdminTheme.textSecondary),
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
                child: const Text('End Call'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await CallService().endCall(widget.call.id);
    }
  }
}

class _DurationTimer extends StatefulWidget {
  final DateTime startTime;
  const _DurationTimer({required this.startTime});

  @override
  State<_DurationTimer> createState() => _DurationTimerState();
}

class _DurationTimerState extends State<_DurationTimer> {
  late Timer _timer;
  String _formatted = '00:00';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
  }

  void _updateTime() {
    final duration = DateTime.now().difference(widget.startTime);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _formatted = '$minutes:$seconds';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AdminTheme.errorRed, // Recording dot style
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

