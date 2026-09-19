import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/experience_model.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import 'experience_detail_modal.dart';

/// Public profile screen for a local guide, showcasing bio, verified credentials,
/// and all expeditions/experiences created by this guide till date.
class GuidePublicProfileScreen extends StatelessWidget {
  final UserModel guide;

  const GuidePublicProfileScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final expRepo = ExperienceRepository();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        physics: bespokeBouncingScrollPhysics,
        slivers: [
          // Header with back button & Guide Cover
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.headerNavy,
            leading: CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.headerNavy,
                      AppColors.travellerForestDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.explore,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ),

          // Guide Profile Details & Bio
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo with Verified Ring
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.travellerForestDark,
                            backgroundImage: guide.profilePicUrl.isNotEmpty
                                ? CachedNetworkImageProvider(guide.profilePicUrl)
                                : null,
                            child: guide.profilePicUrl.isEmpty
                                ? Text(
                                    guide.name.isNotEmpty ? guide.name[0].toUpperCase() : 'G',
                                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        guide.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified, color: AppColors.brandGreen, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  guide.city.isNotEmpty
                                      ? '${guide.city}, ${guide.state}'
                                      : (guide.state.isNotEmpty ? guide.state : 'Verified Host'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Stats Chips Row
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.shield,
                          label: 'Aadhaar Verified',
                          color: AppColors.brandGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          icon: Icons.work_history_outlined,
                          label: '${guide.experienceYears > 0 ? guide.experienceYears : 3}+ Yrs Experience',
                          color: AppColors.headerNavy,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          icon: Icons.star,
                          label: '${guide.rating > 0 ? guide.rating.toStringAsFixed(1) : '4.9'} ★',
                          color: Colors.amber.shade800,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bio Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About Host',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.travellerForestDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            guide.bio.isNotEmpty
                                ? guide.bio
                                : 'Passionate local guide dedicated to revealing hidden gems, ancient trails, and rich cultural traditions with maximum hospitality and safety.',
                            style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMain),
                          ),
                          if (guide.languages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Languages Spoken',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: guide.languages.map((lang) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.travellerSoftMint.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lang,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.travellerForestDark,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (guide.phone.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse('tel:${guide.phone}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                icon: const Icon(Icons.phone, size: 16, color: AppColors.travellerForestDark),
                                label: const Text('Contact Local Guide', style: TextStyle(color: AppColors.travellerForestDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.travellerForestDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Heading: Experiences Made by this Guide Till Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Experiences by ${guide.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.travellerForestDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap any experience below to view complete details & itinerary.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),

          // Stream of all Experiences Made by This Guide
          StreamBuilder<List<ExperienceModel>>(
            stream: expRepo.getGuideExperiencesStream(guide.uid, guide.email, guide.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final experiences = snapshot.data ?? [];

              if (experiences.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.landscape_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Public Experiences Yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${guide.name} has not published any public experiences at this time.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = experiences[index];
                      final cover = exp.images.isNotEmpty
                          ? exp.images.first
                          : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: SpringCard(
                          borderRadius: 16,
                          scaleDown: 0.98,
                          onTap: () {
                            ExperienceDetailModal.show(context, exp);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: cover,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    width: 110,
                                    height: 110,
                                    color: AppColors.travellerForestDark.withValues(alpha: 0.1),
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    width: 110,
                                    height: 110,
                                    color: AppColors.travellerForestDark,
                                    child: const Icon(Icons.image, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.headerNavy.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            exp.category.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.headerNavy,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          exp.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textMain,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '${exp.durationDays}D / ${exp.durationNights}N',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('·', style: TextStyle(color: AppColors.textMuted)),
                                            const SizedBox(width: 8),
                                            Text(
                                              '₹${exp.price.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.travellerForestDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 12.0),
                                  child: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: experiences.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
