import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/experience_model.dart';

class ExperienceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all approved/published public itineraries for Travellers from both 'itineraries' & 'experiences'
  Stream<List<ExperienceModel>> getApprovedExperiencesStream() {
    final itinerariesStream = _firestore.collection('itineraries').snapshots();
    final experiencesStream = _firestore.collection('experiences').snapshots();

    return itinerariesStream.asyncExpand((itinerariesSnap) {
      return experiencesStream.map((experiencesSnap) {
        final Map<String, ExperienceModel> map = {};

        // Parse legacy 'experiences' collection
        for (var doc in experiencesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (exp.status.trim().isEmpty || exp.status == 'approved' || exp.status == 'published' || exp.status == 'active') {
              map[exp.id] = exp;
            }
          } catch (e) {
            debugPrint('Error parsing experience doc ${doc.id}: $e');
          }
        }

        // Parse new 'itineraries' collection (overrides if duplicate id)
        for (var doc in itinerariesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (exp.status.trim().isEmpty || exp.status == 'approved' || exp.status == 'published' || exp.status == 'active') {
              map[exp.id] = exp;
            }
          } catch (e) {
            debugPrint('Error parsing itinerary doc ${doc.id}: $e');
          }
        }

        final list = map.values.toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    });
  }

  // Fetch itineraries belonging to a specific guide from both collections (by ID or Email)
  Stream<List<ExperienceModel>> getGuideExperiencesStream(String guideId, [String? guideEmail]) {
    final itinerariesStream = _firestore.collection('itineraries').snapshots();
    final experiencesStream = _firestore.collection('experiences').snapshots();

    return itinerariesStream.asyncExpand((itinerariesSnap) {
      return experiencesStream.map((experiencesSnap) {
        final Map<String, ExperienceModel> map = {};

        bool matchesGuide(ExperienceModel exp) {
          final idMatch = guideId.isNotEmpty && exp.guideId == guideId;
          final emailMatch = guideEmail != null &&
              guideEmail.isNotEmpty &&
              exp.guideId.toLowerCase().trim() == guideEmail.toLowerCase().trim();
          return idMatch || emailMatch;
        }

        for (var doc in experiencesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (matchesGuide(exp)) {
              map[exp.id] = exp;
            }
          } catch (e) {
            debugPrint('Error parsing guide experience doc ${doc.id}: $e');
          }
        }

        for (var doc in itinerariesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (matchesGuide(exp)) {
              map[exp.id] = exp;
            }
          } catch (e) {
            debugPrint('Error parsing guide itinerary doc ${doc.id}: $e');
          }
        }

        final list = map.values.toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    });
  }

  // Fetch single itinerary detail from itineraries or experiences
  Future<ExperienceModel?> getExperienceById(String id) async {
    try {
      final doc = await _firestore.collection('itineraries').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ExperienceModel.fromMap(doc.data()!, doc.id);
      }

      final legacyDoc = await _firestore.collection('experiences').doc(id).get();
      if (legacyDoc.exists && legacyDoc.data() != null) {
        return ExperienceModel.fromMap(legacyDoc.data()!, legacyDoc.id);
      }
    } catch (e) {
      debugPrint('ExperienceRepository.getExperienceById Error: $e');
    }
    return null;
  }

  // Create or Update Itinerary
  Future<String> saveItinerary(ExperienceModel experience) async {
    final docRef = experience.id.isNotEmpty
        ? _firestore.collection('itineraries').doc(experience.id)
        : _firestore.collection('itineraries').doc();

    final data = experience.toMap();
    data['id'] = docRef.id;
    data['status'] = 'pending'; // Requires admin approval upon submit/edit

    await docRef.set(data, SetOptions(merge: true));
    return docRef.id;
  }

  // Delete Itinerary
  Future<void> deleteItinerary(String id) async {
    await _firestore.collection('itineraries').doc(id).delete();
  }
}
