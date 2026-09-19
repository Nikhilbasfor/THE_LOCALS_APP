import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/experience_model.dart';
import '../../models/booking_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/experience_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import '../../widgets/travel_pattern_background.dart';
import 'experience_detail_modal.dart';
import 'verified_guides_screen.dart';
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
      body: TravelPatternBackground(
        child: SingleChildScrollView(
          physics: bespokeBouncingScrollPhysics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Hero Header Bar (Shortened Breadth)
              Container(
                color: AppColors.travellerForestDark,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: FutureBuilder(
                        future: user != null ? _authRepo.getUserProfile(user.uid) : Future.value(null),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.name ?? user?.displayName ?? 'Explorer';
                          return Text(
                            'Welcome back, $name!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.travellerSoftMint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.travellerSoftMint.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: AppColors.travellerSoftMint),
                          SizedBox(width: 4),
                          Text(
                            'Expedition Hub',
                            style: TextStyle(
                              color: AppColors.travellerSoftMint,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).staggeredEntrance(index: 0),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scenic Unsplash Banner Carousel
                  _buildScenicHeroBanner().staggeredEntrance(index: 1),

                  const SizedBox(height: 20),

                  // Quick Action Grid Tiles
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const VerifiedGuidesScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).staggeredEntrance(index: 2),

                  const SizedBox(height: 22),

                  // Upcoming Journey / Active Booking Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Expedition',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                      ),
                      const SizedBox(height: 10),
                      _buildUpcomingBookingCard(user),
                    ],
                  ).staggeredEntrance(index: 3),

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
                  ).staggeredEntrance(index: 4),
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
    ),
  );
  }

  Widget _buildScenicHeroBanner() {
    return SpringCard(
      borderRadius: 18,
      scaleDown: 0.98,
      child: Container(
        width: double.infinity,
        height: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: const DecorationImage(
            image: CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80',
            ),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Handcrafted Local Expeditions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Your personal hub for authentic guided expeditions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
    return SpringCard(
      onTap: onTap,
      scaleDown: 0.95,
      borderRadius: 14,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
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
        return SpringCard(
          scaleDown: 0.97,
          borderRadius: 16,
          color: Colors.white,
          border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.4)),
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
        );
      },
    );
  }

  Widget _buildNoBookingCard() {
    return SpringCard(
      borderRadius: 16,
      scaleDown: 0.99,
      padding: const EdgeInsets.all(18),
      border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
      child: Column(
        children: [
          Icon(Icons.hiking, size: 36, color: AppColors.travellerForestDark.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          const Text(
            'No upcoming expeditions booked yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explore multi-day itineraries crafted by verified local experts.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          BouncingButton(
            onPressed: () => widget.onNavigateTab?.call(1),
            backgroundColor: AppColors.travellerForestDark,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            borderRadius: 10,
            child: const Text('Browse Itineraries', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: bespokeBouncingScrollPhysics,
            itemCount: featured.length,
            itemBuilder: (context, idx) {
              final exp = featured[idx];
              final img = exp.images.isNotEmpty ? exp.images.first : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb';

              return Container(
                width: 225,
                margin: const EdgeInsets.only(right: 14),
                child: SpringCard(
                  borderRadius: 16,
                  scaleDown: 0.96,
                  onTap: () {
                    ExperienceDetailModal.show(context, exp);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
                        imageUrl: img,
                        height: 115,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.travellerForestDark.withValues(alpha: 0.1)),
                        errorWidget: (_, _, _) => Container(color: AppColors.travellerForestDark, height: 115),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.travellerForestDark),
                            ),
                            const SizedBox(height: 3),
                            Text('${exp.city}, ${exp.state}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${exp.durationDays}D / ${exp.durationNights}N', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
                                Text('₹${exp.price.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.brandGreen)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).staggeredEntrance(index: idx),
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
                Text('Your Expedition Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
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
