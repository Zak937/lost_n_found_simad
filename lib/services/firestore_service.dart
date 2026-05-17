import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  // ── Storage ───────────────────────────────────────────────
  Future<String> uploadImage(File imageFile, String userId) async {
    final ref = _storage.ref().child(
      'items/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }
}
