class BookingModel {
  final String id;
  final String experienceId;
  final String experienceTitle;
  final String experienceImage;
  final String travellerId;
  final String travellerName;
  final String travellerEmail;
  final String travellerPhone;
  final String guideId;
  final String guideName;
  final String guideEmail;
  final String bookingDate;
  final int numberOfTravelers;
  final double totalPrice;
  final String status; // "pending", "confirmed", "cancelled", "rejected"
  final String paymentStatus; // "unpaid", "paid", "refunded"
  final String paymentId;
  final String specialRequests;
  final int createdAt;

  BookingModel({
    this.id = '',
    this.experienceId = '',
    this.experienceTitle = '',
    this.experienceImage = '',
    this.travellerId = '',
    this.travellerName = '',
    this.travellerEmail = '',
    this.travellerPhone = '',
    this.guideId = '',
    this.guideName = '',
    this.guideEmail = '',
    this.bookingDate = '',
    this.numberOfTravelers = 1,
    this.totalPrice = 0.0,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentId = '',
    this.specialRequests = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      experienceId: map['experienceId'] ?? map['itineraryId'] ?? map['expId'] ?? '',
      experienceTitle: map['experienceTitle'] ?? map['itineraryTitle'] ?? map['title'] ?? '',
      experienceImage: map['experienceImage'] ?? map['coverImage'] ?? map['imageUrl'] ?? '',
      travellerId: map['travellerId'] ?? map['userId'] ?? map['user_id'] ?? map['uid'] ?? map['travelerId'] ?? '',
      travellerName: map['travellerName'] ?? map['userName'] ?? map['name'] ?? map['fullName'] ?? '',
      travellerEmail: map['travellerEmail'] ?? map['userEmail'] ?? map['email'] ?? '',
      travellerPhone: map['travellerPhone'] ?? map['userPhone'] ?? map['phone'] ?? '',
      guideId: map['guideId'] ?? map['guide_id'] ?? map['hostId'] ?? map['guideUID'] ?? '',
      guideName: map['guideName'] ?? map['hostName'] ?? '',
      guideEmail: map['guideEmail'] ?? map['hostEmail'] ?? '',
      bookingDate: map['bookingDate'] ?? map['date'] ?? map['startDate'] ?? map['bookingTime'] ?? '',
      numberOfTravelers: (map['numberOfTravelers'] as num?)?.toInt() ?? (map['guests'] as num?)?.toInt() ?? (map['guestsCount'] as num?)?.toInt() ?? (map['pax'] as num?)?.toInt() ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? (map['totalAmount'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] ?? map['bookingStatus'] ?? 'pending').toString().toLowerCase(),
      paymentStatus: (map['paymentStatus'] ?? (map['paymentId'] != null && (map['paymentId'] as String).isNotEmpty ? 'paid' : 'unpaid')).toString().toLowerCase(),
      paymentId: map['paymentId'] ?? map['transactionId'] ?? '',
      specialRequests: map['specialRequests'] ?? map['notes'] ?? map['message'] ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'experienceId': experienceId,
      'experienceTitle': experienceTitle,
      'experienceImage': experienceImage,
      'travellerId': travellerId,
      'travellerName': travellerName,
      'travellerEmail': travellerEmail,
      'travellerPhone': travellerPhone,
      'guideId': guideId,
      'guideName': guideName,
      'guideEmail': guideEmail,
      'bookingDate': bookingDate,
      'numberOfTravelers': numberOfTravelers,
      'totalPrice': totalPrice,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'specialRequests': specialRequests,
      'createdAt': createdAt,
    };
  }
}
