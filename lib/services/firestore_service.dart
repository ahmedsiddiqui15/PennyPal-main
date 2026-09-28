import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/constants/app_constants.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _db.collection(name);

  FirebaseFirestore get db => _db;

  Future<String> create(String collection, Map<String, dynamic> data) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _db.collection(collection).add(data);
    return ref.id;
  }

  Future<void> set(String collection, String id, Map<String, dynamic> data) =>
      _db.collection(collection).doc(id).set(data, SetOptions(merge: true));

  Future<void> delete(String collection, String id) =>
      _db.collection(collection).doc(id).delete();

  
  
  
  Future<List<Map<String, dynamic>>> byUser(
    String collection,
    String userId, {
    String orderField = 'date',
    bool descending = true,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();

    final List<Map<String, dynamic>> items =
        snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

    items.sort((a, b) {
      final dynamic av = a[orderField];
      final dynamic bv = b[orderField];
      final int cmp = _compare(av, bv);
      return descending ? -cmp : cmp;
    });
    return items;
  }

  
  Future<List<Map<String, dynamic>>> all(
    String collection, {
    String? orderField,
    bool descending = true,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(collection).get();
    final List<Map<String, dynamic>> items =
        snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    if (orderField != null) {
      items.sort((a, b) {
        final int cmp = _compare(a[orderField], b[orderField]);
        return descending ? -cmp : cmp;
      });
    }
    return items;
  }

  Future<Map<String, dynamic>?> doc(String collection, String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snap =
        await _db.collection(collection).doc(id).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...?snap.data()};
  }

  Stream<Map<String, dynamic>?> watchDoc(String collection, String id) =>
      _db.collection(collection).doc(id).snapshots().map(
            (snap) => snap.exists ? {'id': snap.id, ...?snap.data()} : null,
          );

  int _compare(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is Timestamp && b is Timestamp) return a.compareTo(b);
    if (a is String && b is String) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }

  
  
  
  
  
  
  
  
  
  
  static void enableOfflinePersistence() {
    if (kIsWeb) return;
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      
    }
  }

  
  static String get users => AppConstants.usersCollection;

  
  
  
  
  
  
  static String describeError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore denied the request. Publish the security rules for '
              'the "users" collection (see README → Security rules).';
        case 'unauthenticated':
          return 'Your session expired. Please sign in again.';
        case 'unavailable':
          return 'Could not reach Firestore. Check your internet connection.';
        case 'not-found':
          return 'Firestore database not found. Create it in the Firebase '
              'console.';
        case 'failed-precondition':
          return 'Firestore is not ready. Create the database in the Firebase '
              'console.';
        case 'resource-exhausted':
          return 'Firestore quota reached. Please try again later.';
        default:
          return 'Firestore error (${error.code}).';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
