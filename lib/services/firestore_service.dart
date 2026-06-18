import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../models/recovery_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users Collection ──────────────────────────────────────
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  // ── Items Collection ──────────────────────────────────────
  Stream<List<ItemModel>> getItems({String? filterType}) {
    Query query = _db
        .collection('items')
        .where('isResolved', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (filterType != null && filterType != 'all') {
      query = query.where('type', isEqualTo: filterType);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) =>
                ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  Stream<List<ItemModel>> getUserItems(String userId) {
    return _db
        .collection('items')
        .where('postedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addItem(ItemModel item) async {
    await _db.collection('items').add(item.toMap());
  }

  Future<void> markResolved(String itemId) async {
    await _db.collection('items').doc(itemId).update({'isResolved': true});
  }

  Future<void> updateItemStatus(
    String itemId,
    String newStatus, {
    bool resolve = false,
  }) async {
    final Map<String, dynamic> data = {'itemStatus': newStatus};
    if (resolve) data['isResolved'] = true;
    await _db.collection('items').doc(itemId).update(data);
  }

  Future<void> updateItemDetails(String itemId, String title, String desc, String location, String category) async {
    await _db.collection('items').doc(itemId).update({
      'title': title,
      'description': desc,
      'location': location,
      'category': category,
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  // Image uploading is handled in separate ImgbbService

  // ── Recoveries Collection (Nested under posts) ─────────────────────────────────
  Future<void> submitRecoveryClaim(RecoveryModel recovery) async {
    final docRef = _db.collection('items').doc(recovery.targetItemId).collection('verifications').doc();
    final newRecovery = RecoveryModel(
      id: docRef.id,
      targetItemId: recovery.targetItemId,
      claimantId: recovery.claimantId,
      claimantEmail: recovery.claimantEmail,
      statement: recovery.statement,
      finderId: recovery.finderId,
      securityCode: recovery.securityCode,
      timestamp: recovery.timestamp,
    );
    await docRef.set(newRecovery.toMap());
    await updateItemStatus(recovery.targetItemId, 'Recovered');
  }

  Future<void> reportFakeClaim(String recoveryId, String itemId) async {
    await _db.collection('items').doc(itemId).collection('verifications').doc(recoveryId).update({'isFakeClaim': true});
    await updateItemStatus(itemId, 'Lost Item');
  }

  Stream<List<RecoveryModel>> getFakeClaims() {
    return _db
        .collectionGroup('verifications')
        .where('isFakeClaim', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => RecoveryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<RecoveryModel?> getRecoveryByItemAndClaimant(String itemId, String claimantId) async {
    final query = await _db
        .collection('items')
        .doc(itemId)
        .collection('verifications')
        .where('claimantId', isEqualTo: claimantId)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return RecoveryModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }
  
  Future<RecoveryModel?> getRecoveryByItemId(String itemId) async {
    final query = await _db
        .collection('items')
        .doc(itemId)
        .collection('verifications')
        .get();
        
    if (query.docs.isNotEmpty) {
      final docs = query.docs;
      docs.sort((a, b) => (b.data()['timestamp'] as Timestamp).compareTo(a.data()['timestamp'] as Timestamp));
      return RecoveryModel.fromMap(docs.first.data(), docs.first.id);
    }
    return null;
  }

  Stream<List<RecoveryModel>> getVerificationsStream(String itemId) {
    return _db
        .collection('items')
        .doc(itemId)
        .collection('verifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => RecoveryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
