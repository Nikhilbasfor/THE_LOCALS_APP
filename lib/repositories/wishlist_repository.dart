import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/wishlist_model.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream user's wishlisted experiences
  Stream<List<WishlistModel>> getUserWishlistStream(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WishlistModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Check if an experience is wishlisted by user
  Stream<bool> isWishlistedStream(String userId, String experienceId) {
    if (userId.isEmpty || experienceId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .where('experienceId', isEqualTo: experienceId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Toggle wishlist item (Add if absent, Remove if present)
  Future<bool> toggleWishlist(String userId, WishlistModel item) async {
    if (userId.isEmpty || item.experienceId.isEmpty) return false;

    try {
      final query = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .where('experienceId', isEqualTo: item.experienceId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Remove from wishlist
        await _firestore.collection('wishlists').doc(query.docs.first.id).delete();
        return false; // Now not wishlisted
      } else {
        // Add to wishlist
        final docRef = _firestore.collection('wishlists').doc();
        final map = item.toMap();
        map['id'] = docRef.id;
        map['userId'] = userId;
        await docRef.set(map);
        return true; // Now wishlisted
      }
    } catch (e) {
      debugPrint('WishlistRepository.toggleWishlist Error: $e');
      return false;
    }
  }

  // Remove from wishlist by doc ID
  Future<void> removeFromWishlist(String docId) async {
    try {
      await _firestore.collection('wishlists').doc(docId).delete();
    } catch (e) {
      debugPrint('WishlistRepository.removeFromWishlist Error: $e');
    }
  }
}
