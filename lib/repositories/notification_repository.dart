import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(List<String> notificationIds) async {
    final batch = _firestore.batch();
    for (final id in notificationIds) {
      final ref = _firestore.collection('notifications').doc(id);
      batch.update(ref, {'read': true});
    }
    await batch.commit();
  }
}
