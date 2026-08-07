import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream reviews for a specific experience
  Stream<List<ReviewModel>> getReviewsForExperienceStream(String experienceId) {
    if (experienceId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('reviews')
        .where('experienceId', isEqualTo: experienceId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Add a review for an experience
  Future<void> addReview(ReviewModel review) async {
    try {
      final docRef = _firestore.collection('reviews').doc();
      final data = review.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);
    } catch (e) {
      debugPrint('ReviewRepository.addReview Error: $e');
    }
  }
}
