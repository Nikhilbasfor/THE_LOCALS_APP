import 'package:flutter/material.dart';
import '../../models/experience_model.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';
import 'experience_detail_screen.dart';
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

  static const List<String> categories = [
    'All',
    'Trekking',
    'Heritage',
    'Cultural',
    'Adventure',
    'Spiritual',
    'Culinary',
  ];

  static const List<String> indianStates = [
    'All States',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman & Nicobar Islands',
    'Chandigarh',
    'Dadra & Nagar Haveli & Daman & Diu',
    'Delhi (NCT)',
    'Jammu & Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Header Filter Section
          Container(
            color: AppColors.travellerForestDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search destinations, guides or titles...',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(25),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // State Filter & Category Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedState,
                        dropdownColor: AppColors.travellerForestDark,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        onChanged: (val) => setState(() => _selectedState = val ?? 'All States'),
                        items: indianStates
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final cat = categories[idx];
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat, style: TextStyle(color: isSel ? AppColors.travellerForestDark : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: isSel,
                              selectedColor: AppColors.travellerSoftMint,
                              backgroundColor: Colors.white.withAlpha(25),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Itinerary List
          Expanded(
            child: StreamBuilder<List<ExperienceModel>>(
              stream: _expRepo.getApprovedExperiencesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var list = snapshot.data ?? [];

                // Filter logic
                if (_selectedCategory != 'All') {
                  list = list.where((e) => e.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
                }
                if (_selectedState != 'All States') {
                  list = list.where((e) => e.state.toLowerCase() == _selectedState.toLowerCase()).toList();
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.landscape, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No itineraries found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try adjusting your state or search filter',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final exp = list[idx];
                    return _ExperienceCard(
                      experience: exp,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExperienceDetailScreen(experience: exp),
                          ),
                        );
                      },
                    );
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

class _ExperienceCard extends StatelessWidget {
  final ExperienceModel experience;
  final VoidCallback onTap;

  const _ExperienceCard({required this.experience, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coverImage = experience.images.isNotEmpty ? experience.images.first : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image & Category Tag
            Stack(
              children: [
                Image.network(
                  coverImage,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 180,
                    color: AppColors.travellerForestDark,
                    child: const Icon(Icons.image, color: Colors.white54, size: 48),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.travellerForestDark.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      experience.category.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Card Details Body
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.brandOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${experience.city}, ${experience.state}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${experience.durationDays}D / ${experience.durationNights}N',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    experience.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.travellerForestDark,
                        child: Text(
                          experience.guideName.isNotEmpty ? experience.guideName[0].toUpperCase() : 'G',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        experience.guideName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                      ),
                      const Spacer(),
                      Text(
                        '₹${experience.price.toInt()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandGreen),
                      ),
                      const Text(
                        ' / person',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
