import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../models/experience_model.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_colors.dart';

class GuideExperienceBookingsScreen extends StatelessWidget {
  final ExperienceModel experience;

  const GuideExperienceBookingsScreen({super.key, required this.experience});

  @override
  Widget build(BuildContext context) {
    final bookingRepo = BookingRepository();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        title: Text(
          'GUEST MANIFEST (${experience.title})',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('experienceId', isEqualTo: experience.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.headerNavy));
          }

          final docs = snapshot.data?.docs ?? [];
          final bookings = docs.map((d) => BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.people_outline, size: 54, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No Guest Bookings Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  SizedBox(height: 4),
                  Text('Bookings for this itinerary will appear here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            );
          }

          final totalGuests = bookings.fold<int>(0, (total, b) => total + b.numberOfTravelers);

          return Column(
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL GUESTS BOOKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        Text('$totalGuests / ${experience.maxGroupSize} Max', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('BOOKINGS COUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        Text('${bookings.length} Orders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, idx) {
                    final b = bookings[idx];
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(b.bookingDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
                                _StatusBadge(status: b.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(b.travellerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                            const SizedBox(height: 4),
                            Text('${b.numberOfTravelers} Guests · ₹${b.totalPrice.toInt()}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            if (b.specialRequests.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                                child: Text('Notes: ${b.specialRequests}', style: const TextStyle(fontSize: 11, color: AppColors.textMain, fontStyle: FontStyle.italic)),
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              children: [
                                if (b.travellerPhone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: AppColors.headerNavy, size: 20),
                                    onPressed: () async {
                                      final uri = Uri.parse('tel:${b.travellerPhone}');
                                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                                    },
                                  ),
                                const Spacer(),
                                if (b.status.toLowerCase() == 'pending') ...[
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandRed)),
                                    onPressed: () => bookingRepo.updateBookingStatus(b.id, 'cancelled'),
                                    child: const Text('Reject', style: TextStyle(color: AppColors.brandRed, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandGreen),
                                    onPressed: () => bookingRepo.updateBookingStatus(b.id, 'confirmed'),
                                    child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.statusPendingBg;
    Color text = AppColors.statusPendingText;

    if (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'approved') {
      bg = AppColors.statusApprovedBg;
      text = AppColors.statusApprovedText;
    } else if (status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected') {
      bg = AppColors.statusRevokedBg;
      text = AppColors.statusRevokedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
