import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/experience_model.dart';
import '../../models/user_model.dart';
import '../../models/wishlist_model.dart';
import '../../models/review_model.dart';
import '../../repositories/wishlist_repository.dart';
import '../../repositories/review_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import 'booking_screen.dart';
import 'guide_public_profile_screen.dart';

/// Modal popup bottom sheet presenting full experience details uploaded by the guide.
/// Features a unified non-split booking action bar and interactive sections.
class ExperienceDetailModal extends StatefulWidget {
  final ExperienceModel experience;

  const ExperienceDetailModal({super.key, required this.experience});

  static Future<void> show(BuildContext context, ExperienceModel experience) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      enableDrag: true,
      isDismissible: true,
      builder: (_) => ExperienceDetailModal(experience: experience),
    );
  }

  @override
  State<ExperienceDetailModal> createState() => _ExperienceDetailModalState();
}

class _ExperienceDetailModalState extends State<ExperienceDetailModal> {
  int _currentImageIdx = 0;

  ExperienceModel get exp => widget.experience;

  @override
  Widget build(BuildContext context) {
    final imagesList = exp.images.isNotEmpty
        ? exp.images
        : ['https://images.unsplash.com/photo-1506744038136-46273834b3fb'];
    final height = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag Handle & Top Controls Overlay
          Stack(
            children: [
              // Photo Carousel
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: imagesList.length,
                      onPageChanged: (idx) => setState(() => _currentImageIdx = idx),
                      itemBuilder: (context, idx) {
                        final imgUrl = imagesList[idx];
                        return CachedNetworkImage(
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
                      },
                    ),

                    // Top Gradient Shadow for close & save buttons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Image Counter Badge
                    if (imagesList.length > 1)
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            '${_currentImageIdx + 1} / ${imagesList.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Drag handle pill centered at top
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              // Close (X) button
              Positioned(
                top: 14,
                left: 14,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // Wishlist Heart Button
              Positioned(
                top: 14,
                right: 14,
                child: Builder(builder: (context) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return const SizedBox.shrink();
                  final wishlistRepo = WishlistRepository();

                  return StreamBuilder<bool>(
                    stream: wishlistRepo.isWishlistedStream(user.uid, exp.id),
                    builder: (context, snapshot) {
                      final isSaved = snapshot.data ?? false;
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.redAccent : Colors.white,
                            size: 18,
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
                      );
                    },
                  );
                }),
              ),
            ],
          ),

          // Scrollable Body with all Guide-Uploaded Details
          Expanded(
            child: SingleChildScrollView(
              physics: bespokeBouncingScrollPhysics,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, size: 14, color: AppColors.brandGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${exp.city.isNotEmpty ? exp.city : 'India'}, ${exp.state}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Experience Title
                  Text(
                    exp.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rating & Reviews Count
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        exp.guideRating > 0 ? exp.guideRating.toStringAsFixed(1) : '4.9',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      const SizedBox(width: 6),
                      const Text('· Verified Expedition', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Verified Guide Card (Tappable to view guide's profile and all experiences)
                  _buildGuideCard(context),
                  const SizedBox(height: 18),

                  // Quick Stats Chips Row
                  Row(
                    children: [
                      _buildStatChip(Icons.calendar_month, '${exp.durationDays} Days / ${exp.durationNights} Nights'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.group, 'Max ${exp.maxGroupSize} People'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(Icons.fitness_center, exp.fitnessLevel.isNotEmpty ? exp.fitnessLevel : 'Moderate'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.wb_sunny_outlined, exp.bestSeason.isNotEmpty ? exp.bestSeason : 'All Season'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Overview Description
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                  const SizedBox(height: 8),
                  Text(
                    exp.description.isNotEmpty ? exp.description : 'Explore authentic local sights and unmissable spots with expert local guidance.',
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 22),

                  // Day-by-Day Itinerary Accordions
                  if (exp.days.isNotEmpty) ...[
                    const Text('Day-by-Day Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 10),
                    ...exp.days.map((day) => _buildDayAccordion(day)),
                    const SizedBox(height: 22),
                  ],

                  // Inclusions & Exclusions
                  if (exp.inclusions.isNotEmpty || exp.exclusions.isNotEmpty) ...[
                    const Text('Inclusions & Exclusions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exp.inclusions.isNotEmpty) ...[
                            const Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppColors.brandGreen),
                                SizedBox(width: 6),
                                Text('INCLUDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandGreen)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...exp.inclusions.map((inc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check, size: 14, color: AppColors.brandGreen),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(inc, style: const TextStyle(fontSize: 12, color: AppColors.textMain))),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 12),
                          ],
                          if (exp.exclusions.isNotEmpty) ...[
                            const Row(
                              children: [
                                Icon(Icons.cancel, size: 14, color: AppColors.brandRed),
                                SizedBox(width: 6),
                                Text('EXCLUDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandRed)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...exp.exclusions.map((exc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.close, size: 14, color: AppColors.brandRed),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(exc, style: const TextStyle(fontSize: 12, color: AppColors.textMain))),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Things to Pack & Carry
                  if (exp.thingsToCarry.isNotEmpty) ...[
                    const Text('Things to Pack & Carry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: exp.thingsToCarry
                            .map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.backpack_outlined, size: 16, color: AppColors.travellerForestDark),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textMain))),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Essential Information & Meeting Point
                  const Text('Essential Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exp.meetingPoint.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.pin_drop, size: 16, color: AppColors.travellerForestDark),
                              SizedBox(width: 8),
                              Text('Meeting Point', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(exp.meetingPoint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final query = Uri.encodeComponent(exp.meetingPoint);
                              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.map, size: 15, color: AppColors.travellerForestDark),
                            label: const Text('Open in Google Maps', style: TextStyle(fontSize: 12, color: AppColors.travellerForestDark, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.travellerForestDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const Divider(height: 20),
                        ],
                        if (exp.permitsRequired.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.assignment, size: 16, color: AppColors.headerNavy),
                              SizedBox(width: 8),
                              Text('Permits & Regulations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(exp.permitsRequired, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const Divider(height: 20),
                        ],
                        if (exp.cancellationPolicy.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                              SizedBox(width: 8),
                              Text('Cancellation Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(exp.cancellationPolicy, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Reviews Section
                  const Text('Traveller Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                  const SizedBox(height: 10),
                  _buildReviewsSection(exp.id),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Unified Non-Split Booking Bar
          _buildUnifiedBookingBar(context),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context) {
    return SpringCard(
      borderRadius: 14,
      scaleDown: 0.98,
      onTap: () {
        final guideModel = UserModel(
          uid: exp.guideId,
          name: exp.guideName,
          email: '',
          role: 'guide',
          profilePicUrl: exp.guideImage,
          phone: exp.guidePhone,
          state: exp.state,
          city: exp.city,
          experienceYears: exp.guideExperienceYears,
          rating: exp.guideRating,
          verified: true,
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GuidePublicProfileScreen(guide: guideModel)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.travellerForestDark,
              backgroundImage: exp.guideImage.isNotEmpty ? CachedNetworkImageProvider(exp.guideImage) : null,
              child: exp.guideImage.isEmpty
                  ? Text(
                      exp.guideName.isNotEmpty ? exp.guideName[0].toUpperCase() : 'G',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exp.guideName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.brandGreen, size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Verified Local Guide · ${exp.guideExperienceYears} Yrs Exp',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.travellerForestDark),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMain),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayAccordion(ItineraryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.travellerForestDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Day ${day.dayNumber}',
              style: const TextStyle(
                color: AppColors.travellerForestDark,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          title: Text(
            day.dayTitle.isNotEmpty ? day.dayTitle : 'Exploration & Journey',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.accommodation.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.hotel, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Stay: ${day.accommodation}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (day.mealsIncluded.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.restaurant, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Meals: ${day.mealsIncluded.join(", ")}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (day.transportInfo.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.directions_car, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Transport: ${day.transportInfo}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (day.activities.isNotEmpty) ...[
                    const Divider(height: 16),
                    ...day.activities.map((act) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.travellerSoftMint.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  act.time.isNotEmpty ? act.time : 'Activity',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(act.activityTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    if (act.description.isNotEmpty)
                                      Text(act.description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(String experienceId) {
    final reviewRepo = ReviewRepository();

    return StreamBuilder<List<ReviewModel>>(
      stream: reviewRepo.getReviewsForExperienceStream(experienceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
            ),
            child: const Row(
              children: [
                Icon(Icons.rate_review_outlined, color: AppColors.textMuted, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No reviews yet. Be the first to embark on this journey!',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: reviews.map((rev) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.travellerForestDark,
                        child: Text(
                          rev.travellerName.isNotEmpty ? rev.travellerName[0].toUpperCase() : 'T',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(rev.travellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (idx) => Icon(
                            idx < rev.rating ? Icons.star : Icons.star_border,
                            size: 13,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (rev.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(rev.comment, style: const TextStyle(fontSize: 11, color: AppColors.textMain, height: 1.4)),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Unified bottom booking bar without split halves.
  /// Seamless single-element surface with total price and booking CTA.
  Widget _buildUnifiedBookingBar(BuildContext context) {
    return Container(
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
    );
  }
}
