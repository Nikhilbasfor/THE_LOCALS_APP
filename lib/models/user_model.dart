class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "traveller" or "guide"
  final String phone;
  final String bio;
  final String profilePicUrl;
  final String state;
  final String city;
  final int experienceYears;
  final double rating;
  final int totalReviews;
  final bool verified;
  final List<String> languages;
  final String aadhaarNumber;
  final String aadhaarFrontUrl;
  final String aadhaarBackUrl;
  final String? rejectionReason;
  final String birthState;
  final List<String> regions;
  final List<String> specialties;
  final bool onboardingComplete;
  final int createdAt;

  UserModel({
    this.uid = '',
    this.name = '',
    this.email = '',
    this.role = 'traveller',
    this.phone = '',
    this.bio = '',
    this.profilePicUrl = '',
    this.state = '',
    this.city = '',
    this.experienceYears = 0,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.verified = false,
    this.languages = const [],
    this.aadhaarNumber = '',
    this.aadhaarFrontUrl = '',
    this.aadhaarBackUrl = '',
    this.rejectionReason,
    this.birthState = '',
    this.regions = const [],
    this.specialties = const [],
    this.onboardingComplete = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId.isNotEmpty ? docId : (map['uid'] ?? ''),
      name: map['name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: (map['role'] ?? 'traveller').toString().toLowerCase(),
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      profilePicUrl: map['profilePicUrl'] ?? map['profileImage'] ?? '',
      state: map['state'] ?? '',
      city: map['city'] ?? '',
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      verified: map['verified'] == true || map['isVerified'] == true,
      languages: (map['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      aadhaarNumber: map['aadhaarNumber'] ?? '',
      aadhaarFrontUrl: map['aadhaarFrontUrl'] ?? '',
      aadhaarBackUrl: map['aadhaarBackUrl'] ?? '',
      rejectionReason: map['rejectionReason'] ?? map['revokeReason'] ?? map['rejection_reason'] ?? map['adminNote'],
      birthState: map['birthState'] ?? '',
      regions: (map['regions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      specialties: (map['specialties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      onboardingComplete: map['onboardingComplete'] ?? false,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'state': state,
      'city': city,
      'experienceYears': experienceYears,
      'rating': rating,
      'totalReviews': totalReviews,
      'verified': verified,
      'languages': languages,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'rejectionReason': rejectionReason,
      'birthState': birthState,
      'regions': regions,
      'specialties': specialties,
      'onboardingComplete': onboardingComplete,
      'createdAt': createdAt,
    };
  }
}
