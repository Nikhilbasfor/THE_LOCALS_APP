class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String itineraryId;
  final int createdAt;
  final bool read;

  NotificationModel({
    this.id = '',
    this.userId = '',
    this.type = '',
    this.title = '',
    this.message = '',
    this.itineraryId = '',
    int? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    int parsedCreatedAt = DateTime.now().millisecondsSinceEpoch;
    final rawTs = map['createdAt'];
    if (rawTs is num) {
      parsedCreatedAt = rawTs.toInt();
    } else if (rawTs != null && rawTs.runtimeType.toString().contains('Timestamp')) {
      parsedCreatedAt = (rawTs as dynamic).toDate().millisecondsSinceEpoch;
    }

    return NotificationModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? (map['type'] ?? '').toString().replaceAll('_', ' '),
      message: map['message'] ?? '',
      itineraryId: map['itineraryId'] ?? map['experienceId'] ?? '',
      createdAt: parsedCreatedAt,
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'itineraryId': itineraryId,
      'createdAt': createdAt,
      'read': read,
    };
  }
}
