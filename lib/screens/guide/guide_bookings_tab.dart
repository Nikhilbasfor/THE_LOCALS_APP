import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_colors.dart';

class GuideBookingsTab extends StatefulWidget {
  const GuideBookingsTab({super.key});

  @override
  State<GuideBookingsTab> createState() => _GuideBookingsTabState();
}

class _GuideBookingsTabState extends State<GuideBookingsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedSubTab = 0;

  final List<String> _subTabs = ['Requests', 'Upcoming', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final guideId = _auth.currentUser?.uid ?? '';

    return Column(
      children: [
        // Sub-tabs bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_subTabs.length, (idx) {
              final isSel = _selectedSubTab == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedSubTab = idx),
                child: Column(
                  children: [
                    Text(
                      _subTabs[idx],
                      style: TextStyle(
                        color: isSel ? AppColors.headerNavy : AppColors.textMuted,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      width: 40,
                      color: isSel ? AppColors.headerNavy : Colors.transparent,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        // Bookings list stream
        Expanded(
          child: StreamBuilder<List<BookingModel>>(
            stream: BookingRepository().getGuideBookingsStream(guideId, FirebaseAuth.instance.currentUser?.email),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.headerNavy));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.textMain),
                  ),
                );
              }

              final allBookings = snapshot.data ?? [];
              final filteredBookings = allBookings.where((booking) {
                final status = booking.status.toLowerCase();
                if (_selectedSubTab == 0) return status == 'pending';
                if (_selectedSubTab == 1) return status == 'confirmed' || status == 'approved';
                if (_selectedSubTab == 2) return status == 'completed';
                if (_selectedSubTab == 3) return status == 'cancelled' || status == 'rejected';
                return true;
              }).toList();

              if (filteredBookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_subTabs[_selectedSubTab].toLowerCase()} bookings found',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredBookings.length,
                itemBuilder: (context, idx) {
                  final booking = filteredBookings[idx];
                  return _buildBookingCard(booking, booking.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.experienceTitle.isNotEmpty ? booking.experienceTitle : 'Experience Booking',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.headerNavy, size: 16),
              const SizedBox(width: 6),
              Text(
                'Traveler: ${booking.travellerName.isNotEmpty ? booking.travellerName : "Anonymous"}',
                style: const TextStyle(color: AppColors.textMain, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'Date: ${booking.bookingDate.isNotEmpty ? booking.bookingDate : "TBD"} • ${booking.numberOfTravelers} Guests',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '₹${booking.totalPrice.toInt()}',
                style: const TextStyle(
                  color: AppColors.headerNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (booking.status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.black12),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateBookingStatus(docId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.brandRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject', style: TextStyle(color: AppColors.brandRed)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateBookingStatus(docId, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept Booking', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else if (booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'approved') ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.black12),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateBookingStatus(docId, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.brandRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel Trip', style: TextStyle(color: AppColors.brandRed)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateBookingStatus(docId, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Mark Completed', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.statusPendingBg;
    Color text = AppColors.statusPendingText;

    final lower = status.toLowerCase();
    if (lower == 'approved' || lower == 'confirmed') {
      bg = AppColors.statusApprovedBg;
      text = AppColors.statusApprovedText;
    } else if (lower == 'completed') {
      bg = const Color(0xFFE0F2FE);
      text = const Color(0xFF0369A1);
    } else if (lower == 'rejected' || lower == 'cancelled') {
      bg = AppColors.statusRevokedBg;
      text = AppColors.statusRevokedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _updateBookingStatus(String docId, String newStatus) async {
    try {
      await BookingRepository().updateBookingStatus(docId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $newStatus successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: AppColors.brandRed),
      );
    }
  }
}
