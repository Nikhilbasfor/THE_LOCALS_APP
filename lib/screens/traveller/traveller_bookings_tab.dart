import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking_model.dart';
import '../../models/review_model.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/review_repository.dart';
import '../../theme/app_colors.dart';

class TravellerBookingsTab extends StatefulWidget {
  const TravellerBookingsTab({super.key});

  @override
  State<TravellerBookingsTab> createState() => _TravellerBookingsTabState();
}

class _TravellerBookingsTabState extends State<TravellerBookingsTab> {
  int _selectedSubTab = 0;
  final List<String> _subTabs = ['Pending', 'Upcoming', 'Completed', 'Cancelled'];

  void _showReviewDialog(BuildContext context, BookingModel booking) {
    double rating = 5.0;
    final commentController = TextEditingController();
    final reviewRepo = ReviewRepository();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Review ${booking.experienceTitle}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your journey with THE LOCALS?', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                    onPressed: () => setDialogState(() => rating = (idx + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share details of your experience...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.travellerForestDark),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final newReview = ReviewModel(
                    experienceId: booking.experienceId,
                    travellerId: user.uid,
                    travellerName: booking.travellerName.isNotEmpty ? booking.travellerName : (user.displayName ?? 'Traveller'),
                    rating: rating,
                    comment: commentController.text.trim(),
                  );
                  await reviewRepo.addReview(newReview);
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you! Your review has been submitted.')),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bookingRepo = BookingRepository();

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.travellerForestDark,
          title: const Text('MY BOOKINGS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view your bookings', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        title: const Text('MY BOOKINGS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingRepo.getTravellerBookingsStream(currentUser.uid, currentUser.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.travellerForestDark));
          }

          final allBookings = snapshot.data ?? [];
          final upcomingCount = allBookings.where((b) => b.status.toLowerCase() == 'confirmed' || b.status.toLowerCase() == 'approved').length;
          final pendingCount = allBookings.where((b) => b.status.toLowerCase() == 'pending').length;
          final completedCount = allBookings.where((b) => b.status.toLowerCase() == 'completed').length;
          final cancelledCount = allBookings.where((b) => b.status.toLowerCase() == 'cancelled' || b.status.toLowerCase() == 'rejected').length;

          // Filter according to sub-tab
          final filteredBookings = allBookings.where((booking) {
            final st = booking.status.toLowerCase();
            if (_selectedSubTab == 0) return st == 'pending';
            if (_selectedSubTab == 1) return st == 'confirmed' || st == 'approved';
            if (_selectedSubTab == 2) return st == 'completed';
            if (_selectedSubTab == 3) return st == 'cancelled' || st == 'rejected';
            return true;
          }).toList();

          return Column(
            children: [
              // Dashboard Summary Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.travellerForestDark, Color(0xFF1B5E4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRAVELLER DASHBOARD', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTravellerStat('Pending', '$pendingCount', Icons.hourglass_top_outlined, () => setState(() => _selectedSubTab = 0)),
                        Container(height: 28, width: 1, color: Colors.white24),
                        _buildTravellerStat('Upcoming', '$upcomingCount', Icons.airplane_ticket_outlined, () => setState(() => _selectedSubTab = 1)),
                        Container(height: 28, width: 1, color: Colors.white24),
                        _buildTravellerStat('Completed', '$completedCount', Icons.verified_outlined, () => setState(() => _selectedSubTab = 2)),
                      ],
                    ),
                  ],
                ),
              ),

              // Sub-Tabs Filter Selector
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: List.generate(_subTabs.length, (idx) {
                    final isSel = _selectedSubTab == idx;
                    int count = 0;
                    if (idx == 0) count = pendingCount;
                    if (idx == 1) count = upcomingCount;
                    if (idx == 2) count = completedCount;
                    if (idx == 3) count = cancelledCount;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSubTab = idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.travellerForestDark : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_subTabs[idx]} ($count)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSel ? Colors.white : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (filteredBookings.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No ${_subTabs[_selectedSubTab]} Bookings', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                        const SizedBox(height: 4),
                        const Text('Explore experiences and book your journey!', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, idx) {
                      final b = filteredBookings[idx];
                      final isCompleted = b.status.toLowerCase() == 'completed';

                      return Card(
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
                                  Text(b.bookingDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                                  _StatusBadge(status: b.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(b.experienceTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Guide: ${b.guideName} · ${b.numberOfTravelers} Travelers', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      Text('₹${b.totalPrice.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                                    ],
                                  ),
                                  if (isCompleted)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.travellerForestDark,
                                        side: const BorderSide(color: AppColors.travellerForestDark),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.star, size: 16, color: Colors.amber),
                                      label: const Text('Write Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showReviewDialog(context, b),
                                    ),
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

  Widget _buildTravellerStat(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
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

    final lower = status.toLowerCase();
    if (lower == 'confirmed' || lower == 'approved') {
      bg = AppColors.statusApprovedBg;
      text = AppColors.statusApprovedText;
    } else if (lower == 'completed') {
      bg = const Color(0xFFE0F2FE);
      text = const Color(0xFF0369A1);
    } else if (lower == 'cancelled' || lower == 'rejected') {
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
