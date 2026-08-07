import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/experience_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';
import 'create_edit_itinerary_screen.dart';

class GuideDashboardTab extends StatelessWidget {
  final Function(int) onNavigateToTab;

  GuideDashboardTab({super.key, required this.onNavigateToTab});

  final ExperienceRepository _expRepo = ExperienceRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final AuthRepository _authRepo = AuthRepository();

  @override
  Widget build(BuildContext context) {
    final user = _authRepo.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view dashboard'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.headerNavy, Color(0xFF2C4A7C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (user.displayName?.isNotEmpty == true) ? user.displayName![0].toUpperCase() : 'G',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guide Dashboard',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.displayName ?? user.email ?? 'Himalayan Guide',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateEditItineraryScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Streams for Stats Cards
          StreamBuilder<List<ExperienceModel>>(
            stream: _expRepo.getGuideExperiencesStream(user.uid, user.email),
            builder: (context, expSnapshot) {
              final experiences = expSnapshot.data ?? [];
              final approvedExp = experiences.where((e) => e.status == 'approved').length;
              final pendingExp = experiences.where((e) => e.status == 'pending').length;

              return StreamBuilder<List<BookingModel>>(
                stream: _bookingRepo.getGuideBookingsStream(user.uid, user.email),
                builder: (context, bookingSnapshot) {
                  final bookings = bookingSnapshot.data ?? [];
                  final pendingBookings = bookings.where((b) => b.status.toLowerCase() == 'pending').toList();
                  final upcomingBookings = bookings.where((b) => b.status.toLowerCase() == 'confirmed' || b.status.toLowerCase() == 'approved').length;
                  final completedBookings = bookings.where((b) => b.status.toLowerCase() == 'completed').length;

                  double totalRevenue = 0.0;
                  for (final b in bookings) {
                    final st = b.status.toLowerCase();
                    if (st == 'confirmed' || st == 'approved' || st == 'completed') {
                      totalRevenue += b.totalPrice;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        children: [
                          _buildStatCard(
                            title: 'Bookings Revenue',
                            value: '₹${totalRevenue.toInt()}',
                            icon: Icons.payments_outlined,
                            color: AppColors.brandGreen,
                            onTap: () => onNavigateToTab(2),
                          ),
                          _buildStatCard(
                            title: 'New Requests',
                            value: '${pendingBookings.length}',
                            icon: Icons.notifications_active_outlined,
                            color: pendingBookings.isNotEmpty ? AppColors.brandRed : AppColors.headerNavy,
                            onTap: () => onNavigateToTab(2),
                          ),
                          _buildStatCard(
                            title: 'Active Experiences',
                            value: '$approvedExp Published',
                            subtitle: '$pendingExp Pending',
                            icon: Icons.map_outlined,
                            color: AppColors.headerNavy,
                            onTap: () => onNavigateToTab(1),
                          ),
                          _buildStatCard(
                            title: 'Upcoming Trips',
                            value: '$upcomingBookings Trips',
                            subtitle: '$completedBookings Completed',
                            icon: Icons.airplane_ticket_outlined,
                            color: Colors.indigo,
                            onTap: () => onNavigateToTab(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pending Booking Requests Preview section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending Booking Requests',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerNavy),
                          ),
                          if (pendingBookings.isNotEmpty)
                            TextButton(
                              onPressed: () => onNavigateToTab(2),
                              child: const Text('View All', style: TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (pendingBookings.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.check_circle_outline, color: AppColors.brandGreen, size: 36),
                              SizedBox(height: 8),
                              Text('No pending booking requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('New bookings from travelers will appear here instantly.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingBookings.length > 3 ? 3 : pendingBookings.length,
                          itemBuilder: (context, idx) {
                            final b = pendingBookings[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFEF3C7),
                                  child: Icon(Icons.person, color: Color(0xFFD97706)),
                                ),
                                title: Text(
                                  b.experienceTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('${b.travellerName} · ${b.bookingDate} · ₹${b.totalPrice.toInt()}'),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () async {
                                    await _bookingRepo.updateBookingStatus(b.id, 'confirmed');
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Booking accepted!')),
                                    );
                                  },
                                  child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
