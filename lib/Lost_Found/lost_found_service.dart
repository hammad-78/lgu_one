import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'lost_found_item.dart';
import 'secret_key_util.dart';

/// Thrown when an entered secret code doesn't match the one stored for an
/// item. Screens catch this to show a friendly "wrong code" message.
class InvalidSecretKeyException implements Exception {
  @override
  String toString() => "That secret code doesn't match this listing.";
}

class LostFoundService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  static const _collection = 'lost_found_items';

  /// Streams all items ordered by newest first. Status/type/category/search
  /// filtering all happens client-side in the listings screen.
  Stream<List<LostFoundItem>> getItems() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LostFoundItem.fromDoc(d)).toList());
  }

  Future<List<String>> _uploadImages(String itemId, List<File> images) async {
    final urls = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < images.length; i++) {
      final ref = _storage.ref('lost_found/$itemId/${stamp}_$i.jpg');
      await ref.putFile(images[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Creates a listing with 'pending' status.
  Future<String> postItem({
    required String type,
    required String category,
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String whatsappNumber,
    required List<File> images,
    String? authorToken,
  }) async {
    final docRef = _firestore.collection(_collection).doc();
    final imageUrls =
    images.isNotEmpty ? await _uploadImages(docRef.id, images) : <String>[];

    final secretKey = SecretKeyUtil.generate();

    await docRef.set({
      'type': type,
      'category': category,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'location': location,
      'date': Timestamp.fromDate(date),
      'whatsappNumber': whatsappNumber,
      'secretKeyHash': SecretKeyUtil.hash(secretKey),
      'status': 'pending', // Initially pending admin approval
      'createdAt': FieldValue.serverTimestamp(),
      'authorToken': authorToken,
    });

    return secretKey;
  }

  Future<bool> verifySecretKey(String itemId, String enteredKey) async {
    final doc = await _firestore.collection(_collection).doc(itemId).get();
    if (!doc.exists) return false;
    final storedHash = doc.data()?['secretKeyHash'] as String? ?? '';
    return storedHash.isNotEmpty &&
        storedHash == SecretKeyUtil.hash(enteredKey);
  }

  Future<void> updateItem({
    required String itemId,
    required String enteredKey,
    required String type,
    required String category,
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String whatsappNumber,
    required List<String> keptImageUrls,
    required List<String> removedImageUrls,
    required List<File> newImages,
  }) async {
    final ok = await verifySecretKey(itemId, enteredKey);
    if (!ok) throw InvalidSecretKeyException();

    final uploaded =
    newImages.isNotEmpty ? await _uploadImages(itemId, newImages) : <String>[];

    await _firestore.collection(_collection).doc(itemId).update({
      'type': type,
      'category': category,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'whatsappNumber': whatsappNumber,
      'imageUrls': [...keptImageUrls, ...uploaded],
    });

    for (final url in removedImageUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }
  }

  Future<void> deleteItem(String itemId, String enteredKey) async {
    final ok = await verifySecretKey(itemId, enteredKey);
    if (!ok) throw InvalidSecretKeyException();

    try {
      final folder = _storage.ref('lost_found/$itemId');
      final listed = await folder.listAll();
      await Future.wait(listed.items.map((ref) => ref.delete()));
    } catch (_) {}

    await _firestore.collection(_collection).doc(itemId).delete();
  }

  /// Admin methods to approve or reject listings
  Future<void> updateItemStatus(String itemId, String status) async {
    await _firestore.collection(_collection).doc(itemId).update({
      'status': status,
    });
  }
}
