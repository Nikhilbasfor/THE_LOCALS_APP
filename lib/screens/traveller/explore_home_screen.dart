import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/geo_data.dart';
import '../../models/experience_model.dart';
import '../../repositories/experience_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import '../../widgets/travel_pattern_background.dart';
import '../guide/guide_onboarding_screen.dart';
import '../login_screen.dart';
import 'experience_detail_modal.dart';
import 'traveller_notification_bell.dart';
import 'traveller_wishlist_tab.dart';

const List<String> exploreCategories = [
  'All',
  'Trek',
  'Cultural',
  'Offbeat',
  'Heritage',
  'Camping',
  'Expedition',
  'Wildlife & Nature',
  'Culinary',
  'Wellness',
];

const List<String> popularDestinations = [
  'All',
  'Ladakh & Zanskar',
  'Spiti Valley',
  'Parvati & Tirthan Valley',
  'Kashmir Valley',
  'Garhwal (Kedarkantha, Har Ki Dun)',
  'Kumaon (Pindari, Munsiyari)',
  'Dzukou Valley (Nagaland)',
  'Ziro Valley (Arunachal)',
  'Meghalaya Living Roots & Cherrapunji',
  'Sikkim & Dzongri',
  'Wayanad & Western Ghats',
  'Munnar & Idukki (Kerala)',
  'Sahyadris (Maharashtra)',
  'Jaisalmer & Thar Desert',
];

class ExploreHomeScreen extends StatefulWidget {
  const ExploreHomeScreen({super.key});

  @override
  State<ExploreHomeScreen> createState() => _ExploreHomeScreenState();
}

class _ExploreHomeScreenState extends State<ExploreHomeScreen> {
  final ExperienceRepository _expRepo = ExperienceRepository();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedState = 'All';
  String _selectedDestination = 'All';
  double _maxPrice = 100000;
  bool _filterDrawerOpen = false;

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_selectedState != 'All' && _selectedState != 'All Regions') count++;
    if (_selectedDestination != 'All') count++;
    if (_maxPrice < 100000) count++;
    return count;
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedState = 'All';
      _selectedDestination = 'All';
      _maxPrice = 100000;
      _searchController.clear();
      _filterDrawerOpen = false;
    });
  }

  String _getExpeditionZone(ExperienceModel exp) {
    final state = exp.state.toLowerCase();
    final location = exp.city.toLowerCase();
    final text = '$state $location ${exp.title.toLowerCase()} ${exp.description.toLowerCase()}';

    // Northeast
    if (text.contains('assam') ||
        text.contains('meghalaya') ||
        text.contains('arunachal') ||
        text.contains('sikkim') ||
        text.contains('nagaland') ||
        text.contains('manipur') ||
        text.contains('mizoram') ||
        text.contains('tripura') ||
        text.contains('dzukou') ||
        text.contains('ziro') ||
        text.contains('kaziranga') ||
        text.contains('cherrapunji') ||
        text.contains('shillong') ||
        text.contains('tawang') ||
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
        text.contains('munnar') ||
        text.contains('coorg') ||
        text.contains('ooty') ||
        text.contains('kodaikanal') ||
        text.contains('western ghats')) {
      return 'South';
    }

    // West
    if (text.contains('maharashtra') ||
        text.contains('gujarat') ||
        text.contains('mumbai') ||
        text.contains('pune') ||
        text.contains('sahyadri') ||
        text.contains('kutch') ||
        text.contains('daman')) {
      return 'West';
    }

    // North (Default)
    return 'North';
  }

  void _showHostTripDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.hiking, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Host a Trip with THE LOCALS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Lead travellers through your ancestral homeland, create authentic itineraries, and earn direct grassroots income.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
              ),
              SizedBox(height: 14),
              Text(
                'Choose how you want to proceed:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF059669)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen(role: 'guide')),
                );
              },
              child: const Text('Sign In as Host', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GuideOnboardingScreen(initialStep: 0)),
                );
              },
              child: const Text('Register as Host', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

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
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'THE LOCALS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          // Host a Trip Toggle / Direct Sign In Button (Requirement 10)
          TextButton.icon(
            onPressed: _showHostTripDialog,
            icon: const Icon(Icons.nature_people, color: Color(0xFF6EE7B7), size: 16),
            label: const Text(
              'Host a Trip',
              style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
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
      ),
      body: TravelPatternBackground(
        child: SingleChildScrollView(
          physics: bespokeBouncingScrollPhysics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HERO BANNER SECTION (Requirements 3 & 4)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.travellerForestDark,
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1200&q=80'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0xDF0A241C),
                      BlendMode.darken,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: DISCOVER HIDDEN EXPERIENCES
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF6EE7B7), size: 12),
                          SizedBox(width: 5),
                          Text(
                            'DISCOVER HIDDEN EXPERIENCES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6EE7B7),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      "What's your next story?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle: Book curated, immersive experiences and intimate journeys led and guided by THE LOCALS
                    const Text(
                      'Book curated, immersive experiences and intimate journeys led and guided by THE LOCALS',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SEARCH BAR (Requirement 4: placeholder "Search by experiences or location")
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Search by experiences or location',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.55),
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.close, color: Colors.white70, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Filters Toggle Button
                        SpringTapFeedback(
                          onTap: () => setState(() => _filterDrawerOpen = !_filterDrawerOpen),
                          scaleDown: 0.94,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: (_activeFiltersCount > 0 || _filterDrawerOpen)
                                  ? AppColors.travellerSoftMint
                                  : Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (_activeFiltersCount > 0 || _filterDrawerOpen)
                                    ? AppColors.travellerSoftMint
                                    : Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: (_activeFiltersCount > 0 || _filterDrawerOpen)
                                      ? AppColors.travellerForestDark
                                      : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _activeFiltersCount > 0 ? 'Filters ($_activeFiltersCount)' : 'Filters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (_activeFiltersCount > 0 || _filterDrawerOpen)
                                        ? AppColors.travellerForestDark
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Filter Drawer (Requirement 4: Max price, state/territory, destinations dropdown, category dropdown)
                    if (_filterDrawerOpen) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Max Price Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('MAX PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                Text('₹${_maxPrice.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                              ],
                            ),
                            Slider(
                              value: _maxPrice,
                              min: 1000,
                              max: 100000,
                              divisions: 99,
                              activeColor: AppColors.travellerForestDark,
                              onChanged: (v) => setState(() => _maxPrice = v),
                            ),
                            const SizedBox(height: 8),

                            // 2. State / Territory Dropdown
                            const Text('STATE / TERRITORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedState,
                              isDense: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: ['All', ...indianStatesAndUTs, 'Nepal', 'Bhutan'].map((st) {
                                return DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedState = v ?? 'All'),
                            ),
                            const SizedBox(height: 10),

                            // 3. Destinations Dropdown (Requirement 4)
                            const Text('DESTINATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedDestination,
                              isDense: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: popularDestinations.map((dst) {
                                return DropdownMenuItem(value: dst, child: Text(dst, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedDestination = v ?? 'All'),
                            ),
                            const SizedBox(height: 10),

                            // 4. Category Dropdown (Requirement 4)
                            const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              isDense: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: exploreCategories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedCategory = v ?? 'All'),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _resetAllFilters,
                                  child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.travellerForestDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: () => setState(() => _filterDrawerOpen = false),
                                  child: const Text('Close Filters', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Category Horizontal Chips
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: bespokeBouncingScrollPhysics,
                        itemCount: exploreCategories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) {
                          final cat = exploreCategories[idx];
                          final isSel = _selectedCategory == cat;
                          return SpringTapFeedback(
                            scaleDown: 0.94,
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.travellerSoftMint : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? AppColors.travellerSoftMint : Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? AppColors.travellerForestDark : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ZONAL EXPEDITIONS OF INDIA (Requirement 5)
              StreamBuilder<List<ExperienceModel>>(
                stream: _expRepo.getApprovedExperiencesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.travellerForestDark)),
                    );
                  }

                  final allExp = snapshot.data ?? [];

                  // Filter logic
                  var filtered = allExp.where((exp) {
                    if (_selectedCategory != 'All' && exp.category.toLowerCase() != _selectedCategory.toLowerCase()) {
                      return false;
                    }
                    if (_selectedState != 'All' && _selectedState != 'All Regions') {
                      final s = _selectedState.toLowerCase();
                      if (!exp.state.toLowerCase().contains(s) && !exp.city.toLowerCase().contains(s)) {
                        return false;
                      }
                    }
                    if (_selectedDestination != 'All') {
                      final d = _selectedDestination.toLowerCase();
                      if (!exp.title.toLowerCase().contains(d) &&
                          !exp.city.toLowerCase().contains(d) &&
                          !exp.state.toLowerCase().contains(d)) {
                        return false;
                      }
                    }
                    if (exp.price > _maxPrice) {
                      return false;
                    }
                    if (_searchController.text.trim().isNotEmpty) {
                      final q = _searchController.text.trim().toLowerCase();
                      if (!exp.title.toLowerCase().contains(q) &&
                          !exp.city.toLowerCase().contains(q) &&
                          !exp.state.toLowerCase().contains(q) &&
                          !exp.guideName.toLowerCase().contains(q) &&
                          !exp.description.toLowerCase().contains(q)) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

                  // Divide into 4 Indian Zonal Sections (Requirement 5)
                  final northeastList = filtered.where((e) => _getExpeditionZone(e) == 'Northeast').toList();
                  final northList = filtered.where((e) => _getExpeditionZone(e) == 'North').toList();
                  final southList = filtered.where((e) => _getExpeditionZone(e) == 'South').toList();
                  final westList = filtered.where((e) => _getExpeditionZone(e) == 'West').toList();

                  return Column(
                    children: [
                      _buildZoneSection('Northeast Expeditions', '🌲', 'Living roots, high passes, sacred monasteries & untouched valleys', northeastList),
                      _buildZoneSection('North Expeditions', '🏔️', 'Himalayan ridges, ancient trade trails & remote mountain homestays', northList),
                      _buildZoneSection('South Expeditions', '🌴', 'Western Ghats rainforests, spice trails & coastal native cultures', southList),
                      _buildZoneSection('West Expeditions', '🏜️', 'Sahyadri cliffside forts, Thar sands & indigenous desert heritage', westList),
                    ],
                  );
                },
              ),

              // WHY CHOOSE THE LOCALS (Mint theme - no black)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6F4EA), Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'WHY CHOOSE THE LOCALS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Conscious Exploration Led by Native Voices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'We are not a mass-commercial travel agency. Here is why our project is fundamentally different:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.35),
                    ),
                    const SizedBox(height: 16),

                    _buildWhyChoosePoint(
                      num: '1',
                      title: '100% Native & Verified Local Hosts',
                      desc: 'Every expedition is led by born-and-raised indigenous mountain residents, certified guides, and elder storytellers. Never outsourced city contractors.',
                      badgeColor: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 12),

                    _buildWhyChoosePoint(
                      num: '2',
                      title: 'Intimate Micro-Groups & Slow Travel',
                      desc: 'Strict caps of 2 to 8 explorers ensure deep immersion, respectful footprint on fragile ecosystems, and meaningful relationships with host families.',
                      badgeColor: const Color(0xFF0284C7),
                    ),
                    const SizedBox(height: 12),

                    _buildWhyChoosePoint(
                      num: '3',
                      title: 'Direct Grassroots Economic Impact',
                      desc: 'Over 85% of expedition payments stay directly inside remote valleys with homestay cooks, porters, and artisan families, keeping villages alive.',
                      badgeColor: const Color(0xFFD97706),
                    ),
                    const SizedBox(height: 12),

                    _buildWhyChoosePoint(
                      num: '4',
                      title: 'Uncommercialized Secret Trails',
                      desc: 'Escape mass-tourism crowds. Discover hidden sacred ridges, ancestral forager paths, forgotten monastic valleys, and authentic harvest festivals.',
                      badgeColor: const Color(0xFFE11D48),
                    ),
                    const SizedBox(height: 16),

                    // Brand Pillars Banner (Requirement 7)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFA7F3D0))),
                      ),
                      child: const Text(
                        'Locals ★ Offbeat ★ Immersive ★ Slow and Sustainable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // BOTTOM FOOTER SECTION (Requirement 8)
              Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THE LOCALS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Curated expeditions led by verified indigenous hosts.',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 20),

                    // Famous 4 Best Expeditions (Requirement 8)
                    const Text(
                      'MOST FAMOUS EXPEDITIONS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7), letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 10),

                    _buildFamousExpeditionItem('Roopkund Mystery Lake Expedition', 'Uttarakhand · 8 Days', '₹18,500'),
                    _buildFamousExpeditionItem('Chadar Frozen River Trek', 'Zanskar, Ladakh · 9 Days', '₹28,000'),
                    _buildFamousExpeditionItem('Dzukou Valley & Hornbill Trail', 'Nagaland · 6 Days', '₹16,200'),
                    _buildFamousExpeditionItem('Markha Valley Wildlife Trail', 'Hemis, Ladakh · 7 Days', '₹19,800'),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 12),

                    // Contact Us Email (Requirement 8)
                    Row(
                      children: const [
                        Icon(Icons.email_outlined, color: Color(0xFF6EE7B7), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Contact Us: support@thelocals.in',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '© 2026 THE LOCALS. All rights reserved.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneSection(String title, String emoji, String tagline, List<ExperienceModel> exps) {
    if (exps.isEmpty && (_searchController.text.isNotEmpty || _selectedCategory != 'All' || _selectedState != 'All')) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.travellerLightMint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${exps.length}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      tagline,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (exps.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                'New local hosts in $title are onboarding soon. Check back shortly!',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exps.length,
              itemBuilder: (context, idx) {
                final exp = exps[idx];
                return _CompactExperienceCard(
                  experience: exp,
                  onTap: () => ExperienceDetailModal.show(context, exp),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWhyChoosePoint({
    required String num,
    required String title,
    required String desc,
    required Color badgeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            num,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamousExpeditionItem(String title, String subtitle, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

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
        height: 125,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left thumbnail image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: coverImage,
                    width: 120,
                    height: 125,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 120,
                      height: 125,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.travellerForestDark),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 120,
                      height: 125,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        experience.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.travellerForestDark),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${experience.city}, ${experience.state}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.travellerForestDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 11, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    experience.guideRating > 0 ? experience.guideRating.toStringAsFixed(1) : '5.0',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          experience.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${experience.durationDays} ${experience.durationDays == 1 ? "Day" : "Days"}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          '₹${experience.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.travellerForestDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
