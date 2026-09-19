import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createBooking(BookingModel booking) async {
    final docRef = _firestore.collection('bookings').doc();
    final data = booking.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);

    // Push notification to the guide (soft fail so booking transaction is never aborted)
    if (booking.guideId.isNotEmpty) {
      try {
        await _firestore.collection('notifications').add({
          'userId': booking.guideId,
          'title': 'New Booking Request',
          'message': '${booking.travellerName} requested a booking for "${booking.experienceTitle}" on ${booking.bookingDate}.',
          'type': 'booking_request',
          'read': false,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint('Note: Notification push to guide failed (non-fatal): $e');
      }
    }

    return docRef.id;
  }

  /// Scoped stream of bookings for a specific traveller (avoids permission denied under security rules)
  Stream<List<BookingModel>> getTravellerBookingsStream(String travellerId, [String? travellerEmail]) {
    if (travellerId.isEmpty) return Stream.value([]);

    // Query strictly scoped by travellerId for Firestore security rules compliance
    return _firestore
        .collection('bookings')
        .where('travellerId', isEqualTo: travellerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Scoped stream of bookings for a specific guide (avoids permission denied under security rules)
  Stream<List<BookingModel>> getGuideBookingsStream(String guideId, [String? guideEmail]) {
    if (guideId.isEmpty) return Stream.value([]);

    // Query strictly scoped by guideId for Firestore security rules compliance
    return _firestore
        .collection('bookings')
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _firestore.collection('bookings').doc(bookingId).update({'status': newStatus});

    // Notify traveller of status update
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final travellerId = data['travellerId'] ?? data['userId'] ?? '';
        final expTitle = data['experienceTitle'] ?? 'your trip';
        if (travellerId.toString().isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': travellerId,
            'title': 'Booking ${newStatus.toUpperCase()}',
            'message': 'Your booking for "$expTitle" has been $newStatus.',
            'type': 'booking_status',
            'read': false,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
    } catch (e) {
      debugPrint('Note: Notification push on booking status update failed (non-fatal): $e');
    }
  }
}
