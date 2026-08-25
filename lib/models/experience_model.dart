class RoutePin {
  final String id;
  final String name;
  final String type; // "start", "stop", "overnight", "highlight", "end"
  final double lat;
  final double lng;
  final String placeId;
  final String address;
  final String googleMapsUrl;

  RoutePin({
    this.id = '',
    this.name = '',
    this.type = 'stop',
    this.lat = 0.0,
    this.lng = 0.0,
    this.placeId = '',
    this.address = '',
    this.googleMapsUrl = '',
  });

  factory RoutePin.fromMap(Map<String, dynamic> map) {
    return RoutePin(
      id: map['id'] ?? '',
      name: map['name'] ?? map['title'] ?? '',
      type: map['type'] ?? 'stop',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      placeId: map['placeId'] ?? '',
      address: map['address'] ?? map['location'] ?? '',
      googleMapsUrl: map['googleMapsUrl'] ?? map['mapsUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'lat': lat,
      'lng': lng,
      'placeId': placeId,
      'address': address,
      'googleMapsUrl': googleMapsUrl,
    };
  }
}

class TimelineItem {
  final String time;
  final String location;
  final String activityTitle;
  final String description;
  final String imageUrl;
  final String highlight;
  final String subtext;
  final String instruction;

  TimelineItem({
    this.time = '',
    this.location = '',
    this.activityTitle = '',
    this.description = '',
    this.imageUrl = '',
    this.highlight = '',
    this.subtext = '',
    this.instruction = '',
  });

  factory TimelineItem.fromMap(Map<String, dynamic> map) {
    return TimelineItem(
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      activityTitle: map['activityTitle'] ?? map['title'] ?? map['location'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      highlight: map['highlight'] ?? '',
      subtext: map['subtext'] ?? '',
      instruction: map['instruction'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'location': location,
      'activityTitle': activityTitle,
      'description': description,
      'imageUrl': imageUrl,
      'highlight': highlight,
      'subtext': subtext,
      'instruction': instruction,
    };
  }
}

class ItineraryDay {
  final int dayNumber;
  final String dayTitle;
  final String accommodation;
  final String accommodationPlaceId;
  final String accommodationMapsUrl;
  final List<String> mealsIncluded;
  final String transportInfo;
  final String overnightStay;
  final List<TimelineItem> activities;
  final List<String> highlights;
  final List<RoutePin> routePins;

  ItineraryDay({
    this.dayNumber = 1,
    this.dayTitle = '',
    this.accommodation = '',
    this.accommodationPlaceId = '',
    this.accommodationMapsUrl = '',
    this.mealsIncluded = const [],
    this.transportInfo = '',
    this.overnightStay = '',
    this.activities = const [],
    this.highlights = const [],
    this.routePins = const [],
  });

  factory ItineraryDay.fromMap(Map<String, dynamic> map) {
    // Activities parsing with TimelineItem fallback
    List<TimelineItem> parsedActivities = [];
    if (map['activities'] != null && map['activities'] is List) {
      parsedActivities = (map['activities'] as List)
          .map((e) => TimelineItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } else if (map['timelineItems'] != null && map['timelineItems'] is List) {
      parsedActivities = (map['timelineItems'] as List)
          .map((e) => TimelineItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return ItineraryDay(
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      dayTitle: map['dayTitle'] ?? map['title'] ?? '',
      accommodation: map['accommodation'] ?? '',
      accommodationPlaceId: map['accommodationPlaceId'] ?? '',
      accommodationMapsUrl: map['accommodationMapsUrl'] ?? '',
      mealsIncluded: (map['mealsIncluded'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      transportInfo: map['transportInfo'] ?? '',
      overnightStay: map['overnightStay'] ?? '',
      activities: parsedActivities,
      highlights: (map['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      routePins: (map['routePins'] as List<dynamic>?)
              ?.map((e) => RoutePin.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'dayTitle': dayTitle,
      'accommodation': accommodation,
      'accommodationPlaceId': accommodationPlaceId,
      'accommodationMapsUrl': accommodationMapsUrl,
      'mealsIncluded': mealsIncluded,
      'transportInfo': transportInfo,
      'overnightStay': overnightStay,
      'activities': activities.map((e) => e.toMap()).toList(),
      'highlights': highlights,
      'routePins': routePins.map((e) => e.toMap()).toList(),
    };
  }
}

class ExperienceModel {
  final String id;
  final String title;
  final String description;
  final String guideId;
  final String guideName;
  final String guideImage;
  final String guidePhone;
  final double guideRating;
  final int guideExperienceYears;
  final String state;
  final String city;
  final String category;
  final double price;
  final int durationDays;
  final int durationNights;
  final int maxGroupSize;
  final String meetingPoint;
  final String cancellationPolicy;
  final String permitsRequired;
  final String fitnessLevel;
  final String tripType;
  final String emergencyContactInfo;
  final String bestSeason;
  final List<String> thingsToCarry;
  final List<String> tags;
  final List<String> images;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<ItineraryDay> days;
  final String status; // "pending", "approved", "rejected", "changes_requested"
  final String rejectionReason;
  final int createdAt;

  ExperienceModel({
    this.id = '',
    this.title = '',
    this.description = '',
    this.guideId = '',
    this.guideName = '',
    this.guideImage = '',
    this.guidePhone = '',
    this.guideRating = 0.0,
    this.guideExperienceYears = 0,
    this.state = '',
    this.city = '',
    this.category = '',
    this.price = 0.0,
    this.durationDays = 1,
    this.durationNights = 0,
    this.maxGroupSize = 10,
    this.meetingPoint = '',
    this.cancellationPolicy = '',
    this.permitsRequired = '',
    this.fitnessLevel = '',
    this.tripType = '',
    this.emergencyContactInfo = '',
    this.bestSeason = '',
    this.thingsToCarry = const [],
    this.tags = const [],
    this.images = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.days = const [],
    this.status = 'pending',
    this.rejectionReason = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory ExperienceModel.fromMap(Map<String, dynamic> map, String docId) {
    // 1. Status normalization
    String rawStatus = (map['status'] ?? map['itineraryStatus'] ?? '').toString().toLowerCase().trim();
    String normalizedStatus = rawStatus;
    if (rawStatus == 'published' || rawStatus == 'active' || rawStatus == 'approved') {
      normalizedStatus = 'approved';
    } else if (rawStatus == 'changes_requested') {
      normalizedStatus = 'changes_requested';
    } else if (rawStatus == 'rejected' || rawStatus == 'revoked') {
      normalizedStatus = 'rejected';
    } else if (rawStatus == 'draft' || rawStatus == 'pending_review' || rawStatus == 'pending' || rawStatus.isEmpty) {
      normalizedStatus = 'pending';
    }

    String parsedRejectionReason = (map['itineraryRejectionReason'] ?? map['rejectionReason'] ?? map['feedback'] ?? '').toString().trim();

    // 2. Images list resolution
    List<String> resolvedImages = [];
    if (map['images'] != null && map['images'] is List && (map['images'] as List).isNotEmpty) {
      resolvedImages = (map['images'] as List).map((e) => e.toString()).toList();
    } else if (map['galleryImages'] != null && map['galleryImages'] is List && (map['galleryImages'] as List).isNotEmpty) {
      resolvedImages = (map['galleryImages'] as List).map((e) => e.toString()).toList();
    }
    if (resolvedImages.isEmpty && map['coverImage'] != null && map['coverImage'].toString().isNotEmpty) {
      resolvedImages.add(map['coverImage'].toString());
    }

    // 3. Days parsing with legacy flat itinerary fallback
    List<ItineraryDay> parsedDays = [];
    if (map['days'] != null && map['days'] is List && (map['days'] as List).isNotEmpty) {
      parsedDays = (map['days'] as List)
          .map((e) => ItineraryDay.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } else if (map['itinerary'] != null && map['itinerary'] is List && (map['itinerary'] as List).isNotEmpty) {
      // Convert legacy flat itinerary steps into a Day 1 structure
      final legacySteps = (map['itinerary'] as List).map((item) {
        final stepMap = Map<String, dynamic>.from(item);
        return TimelineItem(
          time: stepMap['time'] ?? '',
          location: stepMap['location'] ?? '',
          activityTitle: stepMap['location'] ?? 'Activity',
          description: stepMap['description'] ?? '',
        );
      }).toList();

      parsedDays.add(ItineraryDay(
        dayNumber: 1,
        dayTitle: 'Full Day Itinerary',
        activities: legacySteps,
      ));
    }

    // 4. Duration days resolution
    int dDays = (map['durationDays'] as num?)?.toInt() ?? 0;
    if (dDays <= 0 && map['duration'] != null) {
      final durStr = map['duration'].toString();
      final match = RegExp(r'\d+').firstMatch(durStr);
      if (match != null) {
        dDays = int.tryParse(match.group(0)!) ?? 1;
      } else {
        dDays = 1;
      }
    }
    if (dDays <= 0) dDays = 1;

    return ExperienceModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      title: map['title'] ?? map['name'] ?? '',
      description: map['description'] ?? map['about'] ?? '',
      guideId: map['guideId'] ?? map['guide_id'] ?? map['userId'] ?? map['user_id'] ?? map['authorId'] ?? map['guideEmail'] ?? map['email'] ?? '',
      guideName: map['guideName'] ?? map['authorName'] ?? map['guide_name'] ?? map['userName'] ?? map['name'] ?? 'Local Guide',
      guideImage: map['guideImage'] ?? map['profileImage'] ?? map['profilePicUrl'] ?? '',
      guidePhone: map['guidePhone'] ?? map['phone'] ?? '',
      guideRating: (map['guideRating'] as num?)?.toDouble() ?? (map['rating'] as num?)?.toDouble() ?? 0.0,
      guideExperienceYears: (map['guideExperienceYears'] as num?)?.toInt() ?? 0,
      state: map['state'] ?? '',
      city: map['city'] ?? map['location'] ?? '',
      category: map['category'] ?? map['type'] ?? 'Trekking',
      price: (map['price'] as num?)?.toDouble() ?? (map['cost'] as num?)?.toDouble() ?? (map['rate'] as num?)?.toDouble() ?? 0.0,
      durationDays: dDays,
      durationNights: (map['durationNights'] as num?)?.toInt() ?? (dDays > 1 ? dDays - 1 : 0),
      maxGroupSize: (map['maxGroupSize'] as num?)?.toInt() ?? 10,
      meetingPoint: map['meetingPoint'] ?? '',
      cancellationPolicy: map['cancellationPolicy'] ?? '',
      permitsRequired: map['permitsRequired'] ?? '',
      fitnessLevel: map['fitnessLevel'] ?? '',
      tripType: map['tripType'] ?? map['tripMode'] ?? '',
      emergencyContactInfo: map['emergencyContactInfo'] ?? '',
      bestSeason: map['bestSeason'] ?? '',
      thingsToCarry: (map['thingsToCarry'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      images: resolvedImages,
      inclusions: (map['inclusions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      exclusions: (map['exclusions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      days: parsedDays,
      status: normalizedStatus,
      rejectionReason: parsedRejectionReason,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'guideId': guideId,
      'userId': guideId,
      'guideName': guideName,
      'guideImage': guideImage,
      'guidePhone': guidePhone,
      'guideRating': guideRating,
      'guideExperienceYears': guideExperienceYears,
      'state': state,
      'city': city,
      'category': category,
      'price': price,
      'durationDays': durationDays,
      'durationNights': durationNights,
      'maxGroupSize': maxGroupSize,
      'meetingPoint': meetingPoint,
      'cancellationPolicy': cancellationPolicy,
      'permitsRequired': permitsRequired,
      'fitnessLevel': fitnessLevel,
      'tripType': tripType,
      'emergencyContactInfo': emergencyContactInfo,
      'bestSeason': bestSeason,
      'thingsToCarry': thingsToCarry,
      'tags': tags,
      'images': images,
      'inclusions': inclusions,
      'exclusions': exclusions,
      'days': days.map((e) => e.toMap()).toList(),
      'status': status,
      'itineraryStatus': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }
}
