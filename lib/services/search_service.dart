import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();

    // Search in users collection (by name)
    final userNameQuery =
        _firestore
            .collection('users')
            .where('name_lowercase', isGreaterThanOrEqualTo: lowercaseQuery)
            .where(
              'name_lowercase',
              isLessThanOrEqualTo: '$lowercaseQuery\uf8ff',
            )
            .limit(10)
            .get();

    // Search in users collection (by email)
    final userEmailQuery =
        _firestore
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: query)
            .where('email', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get();

    // Search in creators collection (by name)
    final creatorNameQuery =
        _firestore
            .collection('creators')
            .where('name_lowercase', isGreaterThanOrEqualTo: lowercaseQuery)
            .where(
              'name_lowercase',
              isLessThanOrEqualTo: '$lowercaseQuery\uf8ff',
            )
            .limit(10)
            .get();

    // Wait for all queries
    final results_snapshots = await Future.wait([
      userNameQuery,
      userEmailQuery,
      creatorNameQuery,
    ]);

    Map<String, AppUser> resultsMap = {};

    for (var snapshot in results_snapshots) {
      for (var doc in snapshot.docs) {
        final user = AppUser.fromFirestore(doc.data());
        resultsMap[user.uid] = user;
      }
    }

    return resultsMap.values.toList();
  }
}
