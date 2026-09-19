import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/experience_model.dart';
import '../../models/wishlist_model.dart';
import '../../models/review_model.dart';
import '../../repositories/wishlist_repository.dart';
import '../../repositories/review_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import 'booking_screen.dart';

class ExperienceDetailScreen extends StatefulWidget {
  final ExperienceModel experience;

  const ExperienceDetailScreen({super.key, required this.experience});

  @override
  State<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  int _currentImageIdx = 0;

  ExperienceModel get exp => widget.experience;

  @override
  Widget build(BuildContext context) {
    final imagesList = exp.images.isNotEmpty ? exp.images : ['https://images.unsplash.com/photo-1506744038136-46273834b3fb'];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        physics: bespokeBouncingScrollPhysics,
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.travellerForestDark,
            leading: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Builder(builder: (context) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return const SizedBox.shrink();
                final wishlistRepo = WishlistRepository();

                return StreamBuilder<bool>(
                  stream: wishlistRepo.isWishlistedStream(user.uid, exp.id),
                  builder: (context, snapshot) {
                    final isSaved = snapshot.data ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : Colors.white,
                          ),
                          onPressed: () async {
                            final wishItem = WishlistModel(
                              userId: user.uid,
                              experienceId: exp.id,
                              experienceTitle: exp.title,
                              location: exp.city.isNotEmpty ? exp.city : exp.state,
                              price: exp.price,
                              rating: exp.guideRating,
                              category: exp.category,
                              imageUrl: exp.images.isNotEmpty ? exp.images.first : '',
                            );
                            await wishlistRepo.toggleWishlist(user.uid, wishItem);
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: imagesList.length,
                    onPageChanged: (idx) => setState(() => _currentImageIdx = idx),
                    itemBuilder: (context, idx) {
                      final imgUrl = imagesList[idx];
                      final cachedImg = CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.travellerForestDark,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.travellerForestDark,
                          child: const Icon(Icons.image, size: 64, color: Colors.white54),
                        ),
                      );

                      return cachedImg;
                    },
                  ),
                  if (imagesList.length > 1)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIdx + 1} / ${imagesList.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Location Tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.headerNavy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exp.category.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, size: 14, color: AppColors.brandOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${exp.city}, ${exp.state}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ).staggeredEntrance(index: 1),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    exp.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                  ).staggeredEntrance(index: 2),
                  const SizedBox(height: 16),

                  // Guide Info Banner
                  SpringCard(
                    padding: const EdgeInsets.all(12.0),
                    borderRadius: 14,
                    border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.travellerForestDark,
                          child: Text(
                            exp.guideName.isNotEmpty ? exp.guideName[0].toUpperCase() : 'G',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.guideName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Verified Local Guide · ${exp.guideExperienceYears} Yrs Exp',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified, color: AppColors.brandGreen, size: 20),
                      ],
                    ),
                  ).staggeredEntrance(index: 3),
                  const SizedBox(height: 16),

                  // Quick Stats Row
                  Row(
                    children: [
                      _StatChip(icon: Icons.calendar_month, label: '${exp.durationDays} Days / ${exp.durationNights} Nights'),
                      const SizedBox(width: 8),
                      _StatChip(icon: Icons.group, label: 'Max ${exp.maxGroupSize} People'),
                    ],
                  ).staggeredEntrance(index: 4),
                  const SizedBox(height: 20),

                  // Overview Description
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                  const SizedBox(height: 8),
                  Text(
                    exp.description.isNotEmpty ? exp.description : 'Explore authentic local sights and unmissable spots with expert local guidance.',
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 24),

                  // Day-by-Day Itinerary Accordions
                  if (exp.days.isNotEmpty) ...[
                    const Text('Day-by-Day Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 12),
                    ...exp.days.map((day) => _DayAccordionCard(day: day)),
                    const SizedBox(height: 24),
                  ],

                  // Inclusions & Exclusions
                  if (exp.inclusions.isNotEmpty || exp.exclusions.isNotEmpty) ...[
                    const Text('Inclusions & Exclusions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (exp.inclusions.isNotEmpty) ...[
                              const Text('INCLUDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandGreen)),
                              const SizedBox(height: 6),
                              ...exp.inclusions.map((inc) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, size: 14, color: AppColors.brandGreen),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(inc, style: const TextStyle(fontSize: 12))),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 12),
                            ],
                            if (exp.exclusions.isNotEmpty) ...[
                              const Text('EXCLUDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandRed)),
                              const SizedBox(height: 6),
                              ...exp.exclusions.map((exc) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cancel, size: 14, color: AppColors.brandRed),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(exc, style: const TextStyle(fontSize: 12))),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Things To Carry
                  if (exp.thingsToCarry.isNotEmpty) ...[
                    const Text('Things to Pack & Carry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: exp.thingsToCarry
                              .map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.backpack, size: 16, color: AppColors.travellerForestDark),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Important Trip Information
                  if (exp.meetingPoint.isNotEmpty || exp.fitnessLevel.isNotEmpty || exp.permitsRequired.isNotEmpty) ...[
                    const Text('Essential Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            if (exp.meetingPoint.isNotEmpty) ...[
                              _MetaInfoRow(icon: Icons.place, title: 'Meeting Point', detail: exp.meetingPoint),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final query = Uri.encodeComponent(exp.meetingPoint);
                                  final mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                                  if (await canLaunchUrl(mapsUri)) {
                                    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.travellerLightMint,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.travellerForestDark.withAlpha(40)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.directions, size: 16, color: AppColors.travellerForestDark),
                                      SizedBox(width: 6),
                                      Text(
                                        'Navigate to Meeting Spot on Google Maps 🗺️',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (exp.fitnessLevel.isNotEmpty)
                              _MetaInfoRow(icon: Icons.fitness_center, title: 'Fitness Level', detail: exp.fitnessLevel),
                            if (exp.permitsRequired.isNotEmpty)
                              _MetaInfoRow(icon: Icons.description, title: 'Permits Required', detail: exp.permitsRequired),
                            if (exp.cancellationPolicy.isNotEmpty)
                              _MetaInfoRow(icon: Icons.policy, title: 'Cancellation Policy', detail: exp.cancellationPolicy),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Customer Reviews & Ratings
                  const Text('Traveller Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                  const SizedBox(height: 12),
                  _ReviewsSection(experienceId: exp.id),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Booking Bar (Unified single bar, not split)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BouncingButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingScreen(experience: exp),
                ),
              );
            },
            backgroundColor: AppColors.travellerForestDark,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PRICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${exp.price.toInt()} / person',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white30, width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Book Journey Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.travellerLightMint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.travellerForestDark.withAlpha(25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.travellerForestDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.travellerForestDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayAccordionCard extends StatelessWidget {
  final ItineraryDay day;

  const _DayAccordionCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text('Day ${day.dayNumber}: ${day.dayTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: day.accommodation.isNotEmpty
            ? Text('Stay: ${day.accommodation}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.accommodation.isNotEmpty || day.accommodationMapsUrl.isNotEmpty) ...[
                  InkWell(
                    onTap: () async {
                      final urlStr = day.accommodationMapsUrl.isNotEmpty
                          ? day.accommodationMapsUrl
                          : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(day.accommodation)}';
                      final uri = Uri.parse(urlStr);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.skyBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, size: 16, color: AppColors.headerNavy),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Open "${day.accommodation.isNotEmpty ? day.accommodation : 'Lodging'}" in Google Maps 🗺️',
                              style: const TextStyle(fontSize: 11, color: AppColors.headerNavy, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ...day.activities.map((act) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.headerNavy, borderRadius: BorderRadius.circular(4)),
                            child: Text(act.time, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(act.activityTitle, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _MetaInfoRow({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.travellerForestDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String experienceId;

  const _ReviewsSection({required this.experienceId});

  @override
  Widget build(BuildContext context) {
    final reviewRepo = ReviewRepository();

    return StreamBuilder<List<ReviewModel>>(
      stream: reviewRepo.getReviewsForExperienceStream(experienceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(Icons.rate_review_outlined, color: AppColors.textMuted),
                  SizedBox(width: 12),
                  Text('No reviews yet. Be the first to share your journey!', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: reviews.map((rev) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.travellerForestDark,
                          child: Text(
                            rev.travellerName.isNotEmpty ? rev.travellerName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(rev.travellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              idx < rev.rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rev.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(rev.comment, style: const TextStyle(fontSize: 12, color: AppColors.textMain, height: 1.4)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
