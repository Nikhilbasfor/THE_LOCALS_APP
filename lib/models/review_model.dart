class ReviewModel {
  final String id;
  final String experienceId;
  final String travellerId;
  final String travellerName;
  final String travellerImage;
  final double rating;
  final String comment;
  final int createdAt;

  ReviewModel({
    this.id = '',
    required this.experienceId,
    required this.travellerId,
    this.travellerName = '',
    this.travellerImage = '',
    this.rating = 5.0,
    this.comment = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      experienceId: map['experienceId'] ?? '',
      travellerId: map['travellerId'] ?? map['userId'] ?? '',
      travellerName: map['travellerName'] ?? map['userName'] ?? 'Anonymous',
      travellerImage: map['travellerImage'] ?? map['userImage'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? map['review'] ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'experienceId': experienceId,
      'travellerId': travellerId,
      'travellerName': travellerName,
      'travellerImage': travellerImage,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
