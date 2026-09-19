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

        bool isApprovedStatus(String status) {
          final s = status.trim().toLowerCase();
          return s == 'approved' || s == 'published' || s == 'active';
        }

        // Parse legacy 'experiences' collection
        for (var doc in experiencesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (isApprovedStatus(exp.status)) {
              map[exp.id] = exp;
            }
          } catch (e) {
            debugPrint('Error parsing experience doc ${doc.id}: $e');
          }
        }

        // Parse 'itineraries' collection (overrides or removes deleted/rejected)
        for (var doc in itinerariesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            final s = exp.status.trim().toLowerCase();
            if (s == 'deleted' || s == 'rejected' || s == 'draft' || s == 'pending' || s == 'changes_requested') {
              map.remove(exp.id);
            } else if (isApprovedStatus(exp.status)) {
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

  // Fetch itineraries belonging to a specific guide from both collections (by ID, Email, or Name)
  Stream<List<ExperienceModel>> getGuideExperiencesStream(String guideId, [String? guideEmail, String? guideName]) {
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
          final nameMatch = guideName != null &&
              guideName.isNotEmpty &&
              exp.guideName.toLowerCase().trim() == guideName.toLowerCase().trim();
          return idMatch || emailMatch || nameMatch;
        }

        for (var doc in experiencesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (matchesGuide(exp)) {
              if (exp.status.trim().toLowerCase() == 'deleted') {
                map.remove(exp.id);
              } else {
                map[exp.id] = exp;
              }
            }
          } catch (e) {
            debugPrint('Error parsing guide experience doc ${doc.id}: $e');
          }
        }

        for (var doc in itinerariesSnap.docs) {
          try {
            final exp = ExperienceModel.fromMap(doc.data(), doc.id);
            if (matchesGuide(exp)) {
              if (exp.status.trim().toLowerCase() == 'deleted') {
                map.remove(exp.id);
              } else {
                map[exp.id] = exp;
              }
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
        final exp = ExperienceModel.fromMap(doc.data()!, doc.id);
        if (exp.status.trim().toLowerCase() != 'deleted') return exp;
      }

      final legacyDoc = await _firestore.collection('experiences').doc(id).get();
      if (legacyDoc.exists && legacyDoc.data() != null) {
        final exp = ExperienceModel.fromMap(legacyDoc.data()!, legacyDoc.id);
        if (exp.status.trim().toLowerCase() != 'deleted') return exp;
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
    data['status'] = 'pending'; // Reset to pending for admin approval
    data['itineraryStatus'] = 'pending';
    data['itineraryVerified'] = false;
    data['itineraryRejectionReason'] = FieldValue.delete();
    data['rejectionReason'] = FieldValue.delete();
    data['feedback'] = FieldValue.delete();

    await docRef.set(data, SetOptions(merge: true));
    return docRef.id;
  }

  // Delete Itinerary from BOTH collections
  Future<void> deleteItinerary(String id) async {
    try {
      await _firestore.collection('itineraries').doc(id).delete();
    } catch (_) {}
    try {
      await _firestore.collection('experiences').doc(id).delete();
    } catch (_) {}
  }
}
