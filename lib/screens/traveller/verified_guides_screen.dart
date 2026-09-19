import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import 'guide_public_profile_screen.dart';

/// Screen listing all verified local guides on the platform.
/// Travellers can search, inspect guide profiles, and view all itineraries hosted by each guide.
class VerifiedGuidesScreen extends StatefulWidget {
  const VerifiedGuidesScreen({super.key});

  @override
  State<VerifiedGuidesScreen> createState() => _VerifiedGuidesScreenState();
}

class _VerifiedGuidesScreenState extends State<VerifiedGuidesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verified Local Guides',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Aadhaar verified hosts & expedition leaders',
              style: TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.headerNavy,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search guides by name, region, or city...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6EE7B7), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6EE7B7), width: 1.5),
                ),
              ),
            ),
          ),

          // Guides Stream List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: authRepo.getGuidesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Unable to load guides: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                final allGuides = snapshot.data ?? [];
                final filteredGuides = allGuides.where((guide) {
                  if (_searchQuery.isEmpty) return true;
                  final matchName = guide.name.toLowerCase().contains(_searchQuery);
                  final matchCity = guide.city.toLowerCase().contains(_searchQuery);
                  final matchState = guide.state.toLowerCase().contains(_searchQuery);
                  final matchLang = guide.languages.any((l) => l.toLowerCase().contains(_searchQuery));
                  return matchName || matchCity || matchState || matchLang;
                }).toList();

                if (filteredGuides.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Verified Guides Found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No guides match "$_searchQuery". Try searching for another city or name.'
                                : 'No verified guides are currently listed. Please check back soon!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  physics: bespokeBouncingScrollPhysics,
                  itemCount: filteredGuides.length,
                  itemBuilder: (context, index) {
                    final guide = filteredGuides[index];
                    return _GuideCard(guide: guide).staggeredEntrance(index: index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final UserModel guide;

  const _GuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: SpringCard(
        borderRadius: 16,
        scaleDown: 0.98,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GuidePublicProfileScreen(guide: guide),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Name, Location & Verified Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.travellerForestDark,
                    backgroundImage: guide.profilePicUrl.isNotEmpty
                        ? CachedNetworkImageProvider(guide.profilePicUrl)
                        : null,
                    child: guide.profilePicUrl.isEmpty
                        ? Text(
                            guide.name.isNotEmpty ? guide.name[0].toUpperCase() : 'G',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                guide.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.brandGreen, size: 18),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: AppColors.brandGreen),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                guide.city.isNotEmpty
                                    ? '${guide.city}, ${guide.state}'
                                    : (guide.state.isNotEmpty ? guide.state : 'Local Explorer'),
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brandGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Aadhaar Verified',
                                style: TextStyle(
                                  color: AppColors.brandGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${guide.experienceYears > 0 ? guide.experienceYears : 3}+ Yrs Exp',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.headerNavy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        guide.rating > 0 ? guide.rating.toStringAsFixed(1) : '4.9',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMain),
                      ),
                    ],
                  ),
                ],
              ),

              // Bio excerpt if available
              if (guide.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  guide.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
              ],

              // Languages Spoken Chips
              if (guide.languages.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: guide.languages.take(3).map((lang) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        lang,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMain, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom Row CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Explore hosted journeys & bio',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandGreen,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 13, color: AppColors.brandGreen),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
