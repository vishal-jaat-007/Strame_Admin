import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final String type;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class RecentActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch combined activities
  Stream<List<ActivityItem>> getActivitiesStream({int limit = 10}) {
    // We can't easily merge streams with limits in a way that respects strict global order without fetching all.
    // For "Recent Activities", we can listen to the top N of each collection and merge them client-side.

    // 1. Users Stream
    final usersStream = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                final timestamp =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                return ActivityItem(
                  id: doc.id,
                  title: 'New user registered',
                  subtitle: '${data['name'] ?? 'Unknown'} joined the platform',
                  timestamp: timestamp,
                  icon: Icons.person_add,
                  color: AdminTheme.electricBlue,
                  type: 'user',
                );
              }).toList(),
        );

    // 2. Creators Stream
    final creatorsStream = _firestore
        .collection('creators')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                final timestamp =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                return ActivityItem(
                  id: doc.id,
                  title: 'Creator approved',
                  subtitle:
                      '${data['displayName'] ?? 'Unknown'} became a creator',
                  timestamp: timestamp,
                  icon: Icons.star,
                  color: AdminTheme.successGreen,
                  type: 'creator',
                );
              }).toList(),
        );

    // 3. Calls Stream
    final callsStream = _firestore
        .collection('call_requests')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                final timestamp =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final status = data['status'] ?? 'unknown';
                return ActivityItem(
                  id: doc.id,
                  title:
                      'Call update', // Could be 'Call started', 'Call ended' based on status
                  subtitle: 'Call status: $status',
                  timestamp: timestamp,
                  icon: status == 'ended' ? Icons.call_end : Icons.call,
                  color: AdminTheme.warningOrange,
                  type: 'call',
                );
              }).toList(),
        );

    // 4. Transactions Stream
    final transactionsStream = _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                final timestamp =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final type = data['type'] ?? 'transaction';
                final amount = (data['amount'] ?? 0).toString();
                return ActivityItem(
                  id: doc.id,
                  title: 'Transaction processed',
                  subtitle: '$type: $amount coins',
                  timestamp: timestamp,
                  icon: Icons.account_balance_wallet,
                  color: AdminTheme.primaryPurple,
                  type: 'transaction',
                );
              }).toList(),
        );

    // 5. Live Sessions Stream
    final liveStream = _firestore
        .collection('live_sessions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                final timestamp =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final status = data['status'] ?? 'unknown';
                return ActivityItem(
                  id: doc.id,
                  title: 'Live session update',
                  subtitle: 'Status: $status',
                  timestamp: timestamp,
                  icon: Icons.live_tv,
                  color: AdminTheme.errorRed,
                  type: 'live',
                );
              }).toList(),
        );

    // Combine using RxDart-like behavior (manually with StreamZip or combineLatest if available,
    // but standard Stream API doesn't have combineLatestList easily.
    // We'll use a custom combiner or just separate streams in the UI?
    // Actually, for a simple dashboard widget, we can use StreamBuilder with a merged stream class
    // or just fetch once. But user wants "Real".

    // Let's use a simple implementation:
    // We will return a Stream that emits whenever ANY of the source streams emit.
    // Since Dart's async package doesn't have combineLatest easily without rxdart,
    // we can use StreamGroup from 'package:async' if available, or just implement a simple merger.

    // Given I can't easily check for 'package:async', I'll implement a simple merge using a StreamController.

    return _mergeStreams([
      usersStream,
      creatorsStream,
      callsStream,
      transactionsStream,
      liveStream,
    ], limit);
  }

  Stream<List<ActivityItem>> _mergeStreams(
    List<Stream<List<ActivityItem>>> streams,
    int limit,
  ) {
    // This is a simplified merge that listens to all and emits combined list
    // It's not perfect but works for dashboard updates
    // Note: This creates a new controller for each call, which is fine.

    // Actually, using StreamZip would wait for all. We want "combineLatest".
    // Since I don't want to add dependencies, I'll use a simpler approach:
    // Just return a Stream that emits the current combined state.

    // However, for the dashboard, maybe it's better to just fetch 5 separate streams in the widget
    // and merge them in the build method? No, that's messy UI code.

    // Let's try to make a custom stream.

    return Stream<List<ActivityItem>>.multi((controller) {
      List<List<ActivityItem>> currentValues = List.generate(
        streams.length,
        (_) => [],
      );
      List<bool> hasEmitted = List.filled(streams.length, false);

      void emitCombined() {
        // Flatten
        final allItems = currentValues.expand((i) => i).toList();
        // Sort
        allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        // Limit
        final limited = allItems.take(limit).toList();
        controller.add(limited);
      }

      for (int i = 0; i < streams.length; i++) {
        streams[i].listen((items) {
          currentValues[i] = items;
          hasEmitted[i] = true;
          emitCombined();
        });
      }
    });
  }
}
