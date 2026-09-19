import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/experience_model.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import '../../widgets/travel_pattern_background.dart';
import 'experience_detail_modal.dart';
import 'traveller_notification_bell.dart';
import 'traveller_wishlist_tab.dart';

class ExploreHomeScreen extends StatefulWidget {
  const ExploreHomeScreen({super.key});

  @override
  State<ExploreHomeScreen> createState() => _ExploreHomeScreenState();
}

class _ExploreHomeScreenState extends State<ExploreHomeScreen> {
  final ExperienceRepository _expRepo = ExperienceRepository();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedState = 'All States';

  static const List<Map<String, dynamic>> categoryItems = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Trekking', 'icon': Icons.hiking_rounded},
    {'name': 'Heritage', 'icon': Icons.account_balance_rounded},
    {'name': 'Cultural', 'icon': Icons.palette_rounded},
    {'name': 'Adventure', 'icon': Icons.kayaking_rounded},
    {'name': 'Wildlife', 'icon': Icons.pets_rounded},
    {'name': 'Culinary', 'icon': Icons.restaurant_rounded},
    {'name': 'Spiritual', 'icon': Icons.spa_rounded},
    {'name': 'Photography', 'icon': Icons.camera_alt_rounded},
  ];

  static const List<String> indianStates = [
    'All States',
    'Arunachal Pradesh',
    'Assam',
    'Himachal Pradesh',
    'Jammu & Kashmir',
    'Ladakh',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Sikkim',
    'Tripura',
    'Uttarakhand',
    'Andhra Pradesh',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
    'Andaman & Nicobar Islands',
    'Delhi (NCT)',
    'Puducherry',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openStateFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredStates = indianStates
                .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grab handle
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Modal Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Destination State',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.travellerForestDark,
                            ),
                          ),
                          if (_selectedState != 'All States')
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedState = 'All States');
                                Navigator.pop(context);
                              },
                              child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // State search box
                      TextField(
                        onChanged: (val) => setModalState(() => query = val),
                        decoration: InputDecoration(
                          hintText: 'Search Indian states & territories...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.travellerForestDark),
                          filled: true,
                          fillColor: AppColors.bgLight,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // State List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          physics: bespokeBouncingScrollPhysics,
                          itemCount: filteredStates.length,
                          itemBuilder: (context, idx) {
                            final stateName = filteredStates[idx];
                            final isSelected = _selectedState == stateName;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              title: Text(
                                stateName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.travellerForestDark : AppColors.textMain,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: AppColors.brandGreen, size: 20)
                                  : null,
                              onTap: () {
                                setState(() => _selectedState = stateName);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        elevation: 0,
        actions: [
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
          const SizedBox(width: 4),
        ],
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
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'THE LOCALS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sleek Header with Unified Search Capsule & State Filter
          Container(
            color: AppColors.travellerForestDark,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: Column(
              children: [
                // Unified Search Capsule with State Selector Pill
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search destinations, guides or titles...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(right: 6),
                            child: const Icon(Icons.close, color: Colors.white60, size: 16),
                          ),
                        ),

                      // State Selector Pill Button
                      SpringTapFeedback(
                        onTap: _openStateFilterModal,
                        scaleDown: 0.94,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedState != 'All States'
                                ? AppColors.travellerSoftMint
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedState != 'All States'
                                  ? AppColors.travellerSoftMint
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 13,
                                color: _selectedState != 'All States'
                                    ? AppColors.travellerForestDark
                                    : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 80),
                                child: Text(
                                  _selectedState == 'All States' ? 'State' : _selectedState,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedState != 'All States'
                                        ? AppColors.travellerForestDark
                                        : Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedState != 'All States') ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedState = 'All States'),
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 13,
                                    color: AppColors.travellerForestDark,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Uncrowded Horizontal Category Carousel with Icons
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: bespokeBouncingScrollPhysics,
                    itemCount: categoryItems.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final item = categoryItems[idx];
                      final String catName = item['name'];
                      final IconData catIcon = item['icon'];
                      final isSel = _selectedCategory == catName;

                      return SpringTapFeedback(
                        scaleDown: 0.94,
                        onTap: () => setState(() => _selectedCategory = catName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.travellerSoftMint
                                : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.travellerSoftMint
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                catIcon,
                                size: 14,
                                color: isSel ? AppColors.travellerForestDark : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                catName,
                                style: TextStyle(
                                  color: isSel ? AppColors.travellerForestDark : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Itinerary List with Watermark Texture Background
          Expanded(
            child: TravelPatternBackground(
              child: StreamBuilder<List<ExperienceModel>>(
                stream: _expRepo.getApprovedExperiencesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.travellerForestDark),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.orange),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Unable to load expeditions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Please check your network connection or try again shortly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                              label: const Text('Retry', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.travellerForestDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var list = snapshot.data ?? [];

                  // Filter logic
                  if (_selectedCategory != 'All') {
                    list = list
                        .where((e) => e.category.toLowerCase() == _selectedCategory.toLowerCase())
                        .toList();
                  }
                  if (_selectedState != 'All States') {
                    list = list
                        .where((e) => e.state.toLowerCase() == _selectedState.toLowerCase())
                        .toList();
                  }
                  if (_searchController.text.trim().isNotEmpty) {
                    final q = _searchController.text.trim().toLowerCase();
                    list = list.where((e) =>
                        e.title.toLowerCase().contains(q) ||
                        e.city.toLowerCase().contains(q) ||
                        e.guideName.toLowerCase().contains(q)).toList();
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.travellerForestDark.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.landscape_outlined,
                                size: 48,
                                color: AppColors.travellerForestDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No expeditions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.travellerForestDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try adjusting your search terms or choosing another state filter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    physics: bespokeBouncingScrollPhysics,
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final exp = list[idx];
                      return _CompactExperienceCard(
                        experience: exp,
                        onTap: () {
                          ExperienceDetailModal.show(context, exp);
                        },
                      ).staggeredEntrance(index: idx);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact horizontal split experience card (~125px height) designed to display
/// 3-4 expeditions simultaneously on a phone screen without overcrowding.
class _CompactExperienceCard extends StatelessWidget {
  final ExperienceModel experience;
  final VoidCallback onTap;

  const _CompactExperienceCard({
    required this.experience,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverImage = experience.images.isNotEmpty
        ? experience.images.first
        : 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80';

    return SpringCard(
      onTap: onTap,
      scaleDown: 0.98,
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 12),
      border: Border.all(
        color: AppColors.cardBorder.withValues(alpha: 0.7),
        width: 1,
      ),
      child: Container(
        height: 126,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Left Content Side (Expanded details)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Location pin and category pill
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.brandOrange),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${experience.city}, ${experience.state}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.travellerForestDark.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          experience.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.travellerForestDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle: Expedition Title (2 lines max)
                  Text(
                    experience.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.travellerForestDark,
                      height: 1.22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Bottom Row: Duration, Guide name, and Price
                  Row(
                    children: [
                      // Duration badge
                      Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 3),
                      Text(
                        '${experience.durationDays}D/${experience.durationNights}N',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      const SizedBox(width: 6),

                      // Guide name
                      Expanded(
                        child: Text(
                          experience.guideName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Price
                      Text(
                        '₹${experience.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right Thumbnail Photo (106x106 rounded)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 106,
                height: 106,
                child: CachedNetworkImage(
                  imageUrl: coverImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.travellerForestDark.withValues(alpha: 0.08),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.travellerForestDark,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.travellerForestDark.withValues(alpha: 0.1),
                    child: const Icon(Icons.image, color: Colors.grey, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
