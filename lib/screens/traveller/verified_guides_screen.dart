import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import 'guide_public_profile_screen.dart';

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

  String _getGuideZone(UserModel guide) {
    final state = guide.state.toLowerCase();
    final city = guide.city.toLowerCase();
    final bio = guide.bio.toLowerCase();
    final text = '$state $city $bio';

    // Northeast
    if (text.contains('assam') ||
        text.contains('meghalaya') ||
        text.contains('arunachal') ||
        text.contains('sikkim') ||
        text.contains('nagaland') ||
        text.contains('manipur') ||
        text.contains('mizoram') ||
        text.contains('tripura') ||
        text.contains('nepal') ||
        text.contains('bhutan')) {
      return 'Northeast';
    }

    // South
    if (text.contains('kerala') ||
        text.contains('tamil') ||
        text.contains('karnataka') ||
        text.contains('goa') ||
        text.contains('andhra') ||
        text.contains('telangana') ||
        text.contains('wayanad') ||
        text.contains('coorg')) {
      return 'South';
    }

    // West
    if (text.contains('maharashtra') ||
        text.contains('gujarat') ||
        text.contains('pune') ||
        text.contains('mumbai') ||
        text.contains('sahyadri')) {
      return 'West';
    }

    // North (default)
    return 'North';
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
              'Aadhaar verified hosts & expedition leaders across India',
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
          // Search Header Bar
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

          // Guides List Divided into Zonal Sections (Requirement 9)
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
                  final matchBio = guide.bio.toLowerCase().contains(_searchQuery);
                  return matchName || matchCity || matchState || matchBio;
                }).toList();

                if (filteredGuides.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No guides found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Try searching with a different name, city, or region.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final northeastGuides = filteredGuides.where((g) => _getGuideZone(g) == 'Northeast').toList();
                final northGuides = filteredGuides.where((g) => _getGuideZone(g) == 'North').toList();
                final southGuides = filteredGuides.where((g) => _getGuideZone(g) == 'South').toList();
                final westGuides = filteredGuides.where((g) => _getGuideZone(g) == 'West').toList();

                return ListView(
                  physics: bespokeBouncingScrollPhysics,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  children: [
                    _buildZoneSection('Northeast Guides', '🌲', 'Native hosts of the seven sisters, Sikkim, Nepal & Bhutan', northeastGuides),
                    _buildZoneSection('North Guides', '🏔️', 'Himalayan mountaineers, high-altitude passes & valley storytellers', northGuides),
                    _buildZoneSection('South Guides', '🌴', 'Western Ghats foragers, coastal navigators & spice naturalists', southGuides),
                    _buildZoneSection('West Guides', '🏜️', 'Sahyadri fort historians & desert wilderness leaders', westGuides),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSection(String title, String emoji, String tagline, List<UserModel> guides) {
    if (guides.isEmpty && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            '${guides.length}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                    Text(tagline, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (guides.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                'New verified guides for $title are onboarding soon.',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ...guides.map((g) => _buildGuideCard(g)),
        ],
      ),
    );
  }

  Widget _buildGuideCard(UserModel guide) {
    final avatar = guide.profilePicUrl.isNotEmpty
        ? guide.profilePicUrl
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80';

    return SpringCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GuidePublicProfileScreen(guide: guide)),
        );
      },
      borderRadius: 14,
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: avatar,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
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
                          guide.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (guide.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 15, color: Color(0xFF059669)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${guide.city.isNotEmpty ? "${guide.city}, " : ""}${guide.state}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (guide.experienceYears > 0) ...[
                        Text(
                          '${guide.experienceYears} yrs exp · ',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                        ),
                      ],
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        guide.rating > 0 ? guide.rating.toStringAsFixed(1) : '5.0',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${guide.totalReviews})',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
