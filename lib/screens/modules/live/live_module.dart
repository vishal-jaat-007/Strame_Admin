import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/admin_theme.dart';
import '../../../services/live_service.dart';
import '../../../models/live_session.dart';
import '../../../widgets/common/user_avatar.dart';

class LiveModule extends StatefulWidget {
  const LiveModule({super.key});

  @override
  State<LiveModule> createState() => _LiveModuleState();
}

class _LiveModuleState extends State<LiveModule> {
  final LiveService _liveService = LiveService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AdminTheme.spacingMd : AdminTheme.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Monitoring',
                  style:
                      isMobile
                          ? AdminTheme.headlineSmall
                          : AdminTheme.headlineMedium,
                ),
                const SizedBox(height: AdminTheme.spacingXs),
                Text(
                  'Monitor and manage active live sessions in real-time.',
                  style: AdminTheme.bodyMedium.copyWith(
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Live stats summary
          StreamBuilder<List<LiveSession>>(
            stream: _liveService.getActiveSessions(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              final totalViewers =
                  snapshot.data?.fold<int>(
                    0,
                    (sum, item) => sum + item.viewerCount,
                  ) ??
                  0;

              if (isMobile) {
                return Column(
                  children: [
                    _StatusCard(
                      label: 'Active Lives',
                      value: '$count',
                      icon: Icons.live_tv_rounded,
                      color: AdminTheme.neonMagenta,
                    ),
                    const SizedBox(height: AdminTheme.spacingMd),
                    _StatusCard(
                      label: 'Total Viewers',
                      value: '$totalViewers',
                      icon: Icons.remove_red_eye_rounded,
                      color: AdminTheme.electricBlue,
                    ),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
                child: Row(
                  children: [
                    _StatusCard(
                      label: 'Active Lives',
                      value: '$count',
                      icon: Icons.live_tv_rounded,
                      color: AdminTheme.neonMagenta,
                    ),
                    const SizedBox(width: AdminTheme.spacingMd),
                    _StatusCard(
                      label: 'Total Viewers',
                      value: '$totalViewers',
                      icon: Icons.remove_red_eye_rounded,
                      color: AdminTheme.electricBlue,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AdminTheme.spacingLg),

          // Content
          StreamBuilder<List<LiveSession>>(
            stream: _liveService.getActiveSessions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AdminTheme.errorRed),
                  ),
                );
              }

              final sessions = snapshot.data ?? [];

              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.live_tv_rounded,
                        size: 64,
                        color: AdminTheme.textSecondary.withOpacity(0.2),
                      ),
                      const SizedBox(height: AdminTheme.spacingMd),
                      Text(
                        'No active live sessions',
                        style: AdminTheme.headlineSmall.copyWith(
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AdminTheme.spacingXl),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (screenWidth < 1100 ? 2 : 3),
                  mainAxisSpacing: AdminTheme.spacingLg,
                  crossAxisSpacing: AdminTheme.spacingLg,
                  childAspectRatio: isMobile ? 1.1 : 0.85,
                ),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  return _LiveSessionCard(
                    session: sessions[index],
                    onEndSession: () => _confirmEndSession(sessions[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmEndSession(LiveSession session) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: const Text(
              'End Live Session?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to forcibly end this live session by ${session.creatorName ?? "Creator"}?',
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.errorRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogContext);
                  try {
                    await _liveService.endSession(session.id);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Live session ended successfully'),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AdminTheme.errorRed,
                      ),
                    );
                  }
                },
                child: const Text('End Session'),
              ),
            ],
          ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AdminTheme.spacingSm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AdminTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: AdminTheme.labelSmall.copyWith(
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: AdminTheme.spacingLg),
        ],
      ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  final LiveSession session;
  final VoidCallback onEndSession;

  const _LiveSessionCard({required this.session, required this.onEndSession});

  Future<Map<String, dynamic>?> _fetchCreator() async {
    if (session.creatorName != null && session.creatorPhotoUrl != null) {
      return {'name': session.creatorName, 'photoUrl': session.creatorPhotoUrl};
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('creators')
              .doc(session.creatorId)
              .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchCreator(),
      builder: (context, snapshot) {
        final creatorData = snapshot.data;
        final name =
            creatorData?['name'] ??
            creatorData?['displayName'] ??
            session.creatorName ??
            'Unknown Creator';
        final photoUrl = creatorData?['photoUrl'] ?? session.creatorPhotoUrl;

        return Container(
          decoration: BoxDecoration(
            color: AdminTheme.cardDark,
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
            border: Border.all(color: AdminTheme.borderColor),
            boxShadow: AdminTheme.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Area
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(color: Colors.black45),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AdminTheme.primaryPurple.withOpacity(0.3),
                              AdminTheme.backgroundPrimary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 64,
                          color: Colors.white10,
                        ),
                      ),

                    // Overlays
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),

                    // Top Badges
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LIVE Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AdminTheme.errorRed,
                              borderRadius: BorderRadius.circular(
                                AdminTheme.radiusXs,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: AdminTheme.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Viewer Count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(
                                AdminTheme.radiusXs,
                              ),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.remove_red_eye_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${session.viewerCount}',
                                  style: AdminTheme.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Info Overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          UserAvatar(
                            photoUrl: photoUrl,
                            radius: 20,
                            name: name,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: AdminTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Started at ${DateFormat('HH:mm').format(session.startedAt)}',
                                  style: AdminTheme.bodySmall.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(color: AdminTheme.cardDarker),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LiveDurationTimer(startedAt: session.startedAt),
                    ElevatedButton.icon(
                      onPressed: onEndSession,
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('End Live'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.errorRed.withOpacity(0.1),
                        foregroundColor: AdminTheme.errorRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ).copyWith(elevation: WidgetStateProperty.all(0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveDurationTimer extends StatefulWidget {
  final DateTime startedAt;

  const _LiveDurationTimer({required this.startedAt});

  @override
  State<_LiveDurationTimer> createState() => _LiveDurationTimerState();
}

class _LiveDurationTimerState extends State<_LiveDurationTimer> {
  late Timer _timer;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.startedAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = DateTime.now().difference(widget.startedAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    final hours =
        _duration.inHours > 0 ? '${twoDigits(_duration.inHours)}:' : '';

    return Row(
      children: [
        Icon(
          Icons.access_time_filled_rounded,
          size: 16,
          color: AdminTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$hours$minutes:$seconds',
          style: AdminTheme.bodyMedium.copyWith(
            color: AdminTheme.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
