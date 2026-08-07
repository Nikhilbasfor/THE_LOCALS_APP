class WishlistModel {
  final String id;
  final String userId;
  final String experienceId;
  final String experienceTitle;
  final String location;
  final double price;
  final double rating;
  final String category;
  final String imageUrl;
  final int createdAt;

  WishlistModel({
    this.id = '',
    required this.userId,
    required this.experienceId,
    this.experienceTitle = '',
    this.location = '',
    this.price = 0.0,
    this.rating = 0.0,
    this.category = '',
    this.imageUrl = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory WishlistModel.fromMap(Map<String, dynamic> map, String docId) {
    return WishlistModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      userId: map['userId'] ?? '',
      experienceId: map['experienceId'] ?? '',
      experienceTitle: map['experienceTitle'] ?? map['title'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? map['coverImage'] ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'experienceId': experienceId,
      'experienceTitle': experienceTitle,
      'location': location,
      'price': price,
      'rating': rating,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}
