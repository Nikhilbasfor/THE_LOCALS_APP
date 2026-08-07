import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/experience_model.dart';
import '../../models/booking_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/experience_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_colors.dart';
import 'experience_detail_screen.dart';
import 'traveller_wishlist_tab.dart';
import 'traveller_notification_bell.dart';

class TravellerDashboardTab extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const TravellerDashboardTab({super.key, this.onNavigateTab});

  @override
  State<TravellerDashboardTab> createState() => _TravellerDashboardTabState();
}

class _TravellerDashboardTabState extends State<TravellerDashboardTab> {
  final AuthRepository _authRepo = AuthRepository();
  final ExperienceRepository _expRepo = ExperienceRepository();
  final BookingRepository _bookingRepo = BookingRepository();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌄';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🏔️';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepo.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'THE LOCALS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Wishlist Heart Icon
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            tooltip: 'My Wishlist',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TravellerWishlistTab()),
              );
            },
          ),
          TravellerNotificationBell(),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Hero Header Bar
            Container(
              color: AppColors.travellerForestDark,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: const TextStyle(color: AppColors.travellerSoftMint, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder(
                    future: user != null ? _authRepo.getUserProfile(user.uid) : Future.value(null),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.name ?? user?.displayName ?? 'Explorer';
                      return Text(
                        'Welcome back, $name!',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your personal hub for authentic Himalayan guided expeditions.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scenic Unsplash Banner Carousel
                  _buildScenicHeroBanner(),

                  const SizedBox(height: 20),

                  // Quick Action Grid Tiles
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.explore,
                          title: 'Explore Trips',
                          subtitle: 'Find local guides',
                          color: const Color(0xFF0284C7),
                          onTap: () => widget.onNavigateTab?.call(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.confirmation_number,
                          title: 'My Bookings',
                          subtitle: 'View status',
                          color: AppColors.brandGreen,
                          onTap: () => widget.onNavigateTab?.call(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.favorite,
                          title: 'Saved Wishlist',
                          subtitle: 'View favorites',
                          color: Colors.redAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TravellerWishlistTab()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.verified_user,
                          title: 'Verified Guides',
                          subtitle: 'Aadhaar checked',
                          color: AppColors.headerNavy,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All guides on THE LOCALS undergo identity & experience verification.'),
                                backgroundColor: AppColors.headerNavy,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Upcoming Journey / Active Booking Section
                  const Text(
                    'Upcoming Expedition',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                  ),
                  const SizedBox(height: 10),
                  _buildUpcomingBookingCard(user),

                  const SizedBox(height: 22),

                  // Featured / Recommended Itineraries
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Itineraries',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateTab?.call(1),
                        child: const Text('View All →', style: TextStyle(color: AppColors.brandGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFeaturedItinerariesStream(),

                  const SizedBox(height: 22),

                  // Travel Tips Widget
                  _buildTravelTipsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenicHeroBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.travellerSoftMint, borderRadius: BorderRadius.circular(4)),
              child: const Text('EXPLORE HIMALAYAS', style: TextStyle(color: AppColors.travellerForestDark, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Handcrafted Local Expeditions',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Connect with certified mountain guides for unforgettable journeys',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain)),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingBookingCard(User? user) {
    if (user == null) {
      return _buildNoBookingCard();
    }

    return StreamBuilder<List<BookingModel>>(
      stream: _bookingRepo.getTravellerBookingsStream(user.uid, user.email),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final activeBookings = bookings
            .where((b) => b.status.toLowerCase() == 'confirmed' || b.status.toLowerCase() == 'approved' || b.status.toLowerCase() == 'pending')
            .toList();

        if (activeBookings.isEmpty) {
          return _buildNoBookingCard();
        }

        final b = activeBookings.first;
        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.brandGreen.withValues(alpha: 0.5))),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: b.status.toLowerCase() == 'pending' ? AppColors.statusPendingBg : AppColors.statusApprovedBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(
                          color: b.status.toLowerCase() == 'pending' ? AppColors.statusPendingText : AppColors.statusApprovedText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('${b.numberOfTravelers} Guests · ₹${b.totalPrice.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  b.experienceTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Guide: ${b.guideName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const Spacer(),
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(b.bookingDate, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoBookingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.hiking, size: 36, color: AppColors.travellerForestDark.withOpacity(0.6)),
          const SizedBox(height: 8),
          const Text(
            'No upcoming expeditions booked yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explore multi-day itineraries crafted by Himalayan local experts.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => widget.onNavigateTab?.call(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.travellerForestDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Browse Itineraries'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedItinerariesStream() {
    return StreamBuilder<List<ExperienceModel>>(
      stream: _expRepo.getApprovedExperiencesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const SizedBox();
        }

        final featured = list.take(4).toList();

        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            itemBuilder: (context, idx) {
              final exp = featured[idx];
              final img = exp.images.isNotEmpty ? exp.images.first : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb';

              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ExperienceDetailScreen(experience: exp)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          img,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: AppColors.travellerForestDark, height: 110),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.travellerForestDark),
                              ),
                              const SizedBox(height: 2),
                              Text('${exp.city}, ${exp.state}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${exp.durationDays}D / ${exp.durationNights}N', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
                                  Text('₹${exp.price.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.brandGreen)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTravelTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates, color: Color(0xFF1D4ED8), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Himalayan Expedition Tip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                SizedBox(height: 2),
                Text('Always carry waterproof layers, thermal gear, and stay hydrated at altitudes above 2,500m.', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
