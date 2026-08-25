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

  // Add a review for an experience or itinerary
  Future<void> addReview(ReviewModel review) async {
    try {
      final docRef = _firestore.collection('reviews').doc();
      final data = review.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);

      // Recalculate average rating & reviewCount for this experienceId
      if (review.experienceId.isNotEmpty) {
        final querySnap = await _firestore
            .collection('reviews')
            .where('experienceId', isEqualTo: review.experienceId)
            .get();

        double totalRating = 0.0;
        int count = 0;
        for (final doc in querySnap.docs) {
          final rData = doc.data();
          final ratingVal = (rData['rating'] as num?)?.toDouble() ?? 0.0;
          if (ratingVal > 0) {
            totalRating += ratingVal;
            count++;
          }
        }

        final double avgRating = count > 0 ? double.parse((totalRating / count).toStringAsFixed(1)) : 0.0;

        // Update in both experiences and itineraries collections if exists
        final expDoc = await _firestore.collection('experiences').doc(review.experienceId).get();
        if (expDoc.exists) {
          await _firestore.collection('experiences').doc(review.experienceId).update({
            'rating': avgRating,
            'reviewCount': count,
          });
        }

        final itinDoc = await _firestore.collection('itineraries').doc(review.experienceId).get();
        if (itinDoc.exists) {
          await _firestore.collection('itineraries').doc(review.experienceId).update({
            'rating': avgRating,
            'reviewCount': count,
          });
        }
      }
    } catch (e) {
      debugPrint('ReviewRepository.addReview Error: $e');
    }
  }
}
