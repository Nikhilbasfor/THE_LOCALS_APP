import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createBooking(BookingModel booking) async {
    final docRef = _firestore.collection('bookings').doc();
    final data = booking.toMap();
    data['id'] = docRef.id;
    await docRef.set(data);

    // Push notification to the guide
    if (booking.guideId.isNotEmpty) {
      await _firestore.collection('notifications').add({
        'userId': booking.guideId,
        'title': 'New Booking Request',
        'message': '${booking.travellerName} requested a booking for "${booking.experienceTitle}" on ${booking.bookingDate}.',
        'type': 'booking_request',
        'read': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return docRef.id;
  }

  Stream<List<BookingModel>> getTravellerBookingsStream(String travellerId, [String? travellerEmail]) {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromMap(doc.data(), doc.id)).where((b) {
        final tIdMatch = travellerId.isNotEmpty && b.travellerId == travellerId;
        final emailMatch = travellerEmail != null &&
            travellerEmail.isNotEmpty &&
            (b.travellerId.toLowerCase().trim() == travellerEmail.toLowerCase().trim() ||
             b.travellerEmail.toLowerCase().trim() == travellerEmail.toLowerCase().trim());
        return tIdMatch || emailMatch;
      }).toList();
    });
  }

  Stream<List<BookingModel>> getGuideBookingsStream(String guideId, [String? guideEmail]) {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromMap(doc.data(), doc.id)).where((b) {
        final gIdMatch = guideId.isNotEmpty && b.guideId == guideId;
        final emailMatch = guideEmail != null &&
            guideEmail.isNotEmpty &&
            (b.guideId.toLowerCase().trim() == guideEmail.toLowerCase().trim() ||
             b.guideEmail.toLowerCase().trim() == guideEmail.toLowerCase().trim());
        return gIdMatch || emailMatch;
      }).toList();
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
    } catch (_) {}
  }
}
