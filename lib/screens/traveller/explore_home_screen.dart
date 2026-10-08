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
  String _selectedState = 'All Regions';
  String _selectedDuration = 'All'; // 'All', '1 Day', '2–4 Days', '5–7 Days', '8+ Days'
  String _selectedPriceRange = 'All'; // 'All', 'Under ₹5k', '₹5k – ₹15k', '₹15k – ₹30k', '₹30k+'

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

  static const List<String> allRegionsAndStates = [
    'All Regions',
    // Himalayan Nations & Cross-Border Regions
    'Nepal',
    'Bhutan',
    'Tibet',
    // Key Himalayan States & UTs
    'Himachal Pradesh',
    'Uttarakhand',
    'Ladakh',
    'Jammu & Kashmir',
    'Sikkim',
    'Arunachal Pradesh',
    'Meghalaya',
    'Assam',
    'Nagaland',
    'Manipur',
    'Mizoram',
    'Tripura',
    // Other Indian States
    'Goa',
    'Rajasthan',
    'Kerala',
    'Karnataka',
    'Maharashtra',
    'West Bengal',
    'Delhi (NCT)',
    'Punjab',
    'Haryana',
    'Madhya Pradesh',
    'Gujarat',
    'Tamil Nadu',
    'Uttar Pradesh',
    'Bihar',
    'Chhattisgarh',
    'Jharkhand',
    'Odisha',
    'Andhra Pradesh',
    'Telangana',
    'Andaman & Nicobar Islands',
    'Puducherry',
  ];

  static const List<String> durationOptions = [
    'All',
    '1 Day',
    '2–4 Days',
    '5–7 Days',
    '8+ Days',
  ];

  static const List<String> priceRangeOptions = [
    'All',
    'Under ₹5k',
    '₹5k – ₹15k',
    '₹15k – ₹30k',
    '₹30k+',
  ];

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_selectedState != 'All Regions' && _selectedState != 'All States') count++;
    if (_selectedDuration != 'All') count++;
    if (_selectedPriceRange != 'All') count++;
    return count;
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedState = 'All Regions';
      _selectedDuration = 'All';
      _selectedPriceRange = 'All';
    });
  }

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
            final filteredStates = allRegionsAndStates
                .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.68,
              minChildSize: 0.4,
              maxChildSize: 0.88,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Destination Region / State',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.travellerForestDark,
                            ),
                          ),
                          if (_selectedState != 'All Regions' && _selectedState != 'All States')
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedState = 'All Regions');
                                Navigator.pop(context);
                              },
                              child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (val) => setModalState(() => query = val),
                        decoration: InputDecoration(
                          hintText: 'Search regions (e.g. Nepal, Bhutan, Himachal)...',
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
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          physics: bespokeBouncingScrollPhysics,
                          itemCount: filteredStates.length,
                          itemBuilder: (context, idx) {
                            final stateName = filteredStates[idx];
                            final isSelected = _selectedState == stateName;
                            final isHimalayan = ['Nepal', 'Bhutan', 'Tibet'].contains(stateName);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              title: Row(
                                children: [
                                  Text(
                                    stateName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppColors.travellerForestDark : AppColors.textMain,
                                    ),
                                  ),
                                  if (isHimalayan) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.travellerLightMint,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Himalayas', style: TextStyle(fontSize: 10, color: AppColors.travellerForestDark, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
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

  void _openFullFilterModal() {
    String tempCategory = _selectedCategory;
    String tempState = _selectedState;
    String tempDuration = _selectedDuration;
    String tempPrice = _selectedPriceRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeCount = (tempCategory != 'All' ? 1 : 0) +
                ((tempState != 'All Regions' && tempState != 'All States') ? 1 : 0) +
                (tempDuration != 'All' ? 1 : 0) +
                (tempPrice != 'All' ? 1 : 0);

            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle and Title Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: Column(
                        children: [
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
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.tune, color: AppColors.travellerForestDark, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Filter Expeditions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.travellerForestDark,
                                    ),
                                  ),
                                ],
                              ),
                              if (activeCount > 0)
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      tempCategory = 'All';
                                      tempState = 'All Regions';
                                      tempDuration = 'All';
                                      tempPrice = 'All';
                                    });
                                  },
                                  child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Filter Options Body
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: bespokeBouncingScrollPhysics,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        children: [
                          // 1. Destination / Region
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Destination / Region', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _openStateFilterModal();
                                },
                                icon: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.travellerForestDark),
                                label: const Text('All States', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'All Regions',
                              'Nepal',
                              'Bhutan',
                              'Tibet',
                              'Himachal Pradesh',
                              'Uttarakhand',
                              'Ladakh',
                              'Sikkim',
                            ].map((st) {
                              final isSel = tempState == st;
                              return ChoiceChip(
                                label: Text(st),
                                selected: isSel,
                                selectedColor: AppColors.travellerSoftMint,
                                backgroundColor: AppColors.bgLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? AppColors.travellerForestDark : AppColors.textMain,
                                ),
                                onSelected: (sel) {
                                  setModalState(() => tempState = sel ? st : 'All Regions');
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // 2. Trip Duration
                          const Text('Trip Duration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: durationOptions.map((dur) {
                              final isSel = tempDuration == dur;
                              return ChoiceChip(
                                label: Text(dur == '1 Day' ? '1 Day (Day Trip)' : dur),
                                selected: isSel,
                                selectedColor: AppColors.travellerSoftMint,
                                backgroundColor: AppColors.bgLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? AppColors.travellerForestDark : AppColors.textMain,
                                ),
                                onSelected: (sel) {
                                  setModalState(() => tempDuration = sel ? dur : 'All');
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // 3. Price Range
                          const Text('Price Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: priceRangeOptions.map((pr) {
                              final isSel = tempPrice == pr;
                              return ChoiceChip(
                                label: Text(pr),
                                selected: isSel,
                                selectedColor: AppColors.travellerSoftMint,
                                backgroundColor: AppColors.bgLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? AppColors.travellerForestDark : AppColors.textMain,
                                ),
                                onSelected: (sel) {
                                  setModalState(() => tempPrice = sel ? pr : 'All');
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // 4. Category
                          const Text('Experience Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categoryItems.map((cat) {
                              final catName = cat['name'] as String;
                              final isSel = tempCategory == catName;
                              return ChoiceChip(
                                label: Text(catName),
                                selected: isSel,
                                selectedColor: AppColors.travellerSoftMint,
                                backgroundColor: AppColors.bgLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? AppColors.travellerForestDark : AppColors.textMain,
                                ),
                                onSelected: (sel) {
                                  setModalState(() => tempCategory = sel ? catName : 'All');
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Apply Button Sticky Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = tempCategory;
                                _selectedState = tempState;
                                _selectedDuration = tempDuration;
                                _selectedPriceRange = tempPrice;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.travellerForestDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              activeCount > 0 ? 'Apply Filters ($activeCount Active)' : 'Apply Filters',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                // Unified Search Capsule with State Selector Pill + Dedicated Tune / Filter Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
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

                            // State / Region Selector Pill Button
                            SpringTapFeedback(
                              onTap: _openStateFilterModal,
                              scaleDown: 0.94,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (_selectedState != 'All Regions' && _selectedState != 'All States')
                                      ? AppColors.travellerSoftMint
                                      : Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_selectedState != 'All Regions' && _selectedState != 'All States')
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
                                      color: (_selectedState != 'All Regions' && _selectedState != 'All States')
                                          ? AppColors.travellerForestDark
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 72),
                                      child: Text(
                                        (_selectedState == 'All Regions' || _selectedState == 'All States') ? 'Region' : _selectedState,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: (_selectedState != 'All Regions' && _selectedState != 'All States')
                                              ? AppColors.travellerForestDark
                                              : Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_selectedState != 'All Regions' && _selectedState != 'All States') ...[
                                      const SizedBox(width: 3),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedState = 'All Regions'),
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
                    ),
                    const SizedBox(width: 8),

                    // Dedicated Tune / Filters Button
                    SpringTapFeedback(
                      onTap: _openFullFilterModal,
                      scaleDown: 0.94,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _activeFiltersCount > 0 ? AppColors.travellerSoftMint : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _activeFiltersCount > 0 ? AppColors.travellerSoftMint : Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 20,
                              color: _activeFiltersCount > 0 ? AppColors.travellerForestDark : Colors.white,
                            ),
                            if (_activeFiltersCount > 0)
                              Positioned(
                                top: -5,
                                right: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                  child: Text(
                                    '$_activeFiltersCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_activeFiltersCount > 0) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 26,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: bespokeBouncingScrollPhysics,
                      children: [
                        if (_selectedState != 'All Regions' && _selectedState != 'All States')
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.travellerSoftMint,
                              label: Text('Region: $_selectedState', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                              deleteIcon: const Icon(Icons.close, size: 12, color: AppColors.travellerForestDark),
                              onDeleted: () => setState(() => _selectedState = 'All Regions'),
                            ),
                          ),
                        if (_selectedDuration != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.travellerSoftMint,
                              label: Text('Duration: $_selectedDuration', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                              deleteIcon: const Icon(Icons.close, size: 12, color: AppColors.travellerForestDark),
                              onDeleted: () => setState(() => _selectedDuration = 'All'),
                            ),
                          ),
                        if (_selectedPriceRange != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.travellerSoftMint,
                              label: Text('Price: $_selectedPriceRange', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                              deleteIcon: const Icon(Icons.close, size: 12, color: AppColors.travellerForestDark),
                              onDeleted: () => setState(() => _selectedPriceRange = 'All'),
                            ),
                          ),
                        GestureDetector(
                          onTap: _resetAllFilters,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  if (_selectedState != 'All States' && _selectedState != 'All Regions') {
                    final stQuery = _selectedState.toLowerCase();
                    list = list
                        .where((e) =>
                            e.state.toLowerCase() == stQuery ||
                            e.city.toLowerCase().contains(stQuery))
                        .toList();
                  }
                  if (_selectedDuration != 'All') {
                    list = list.where((e) {
                      if (_selectedDuration == '1 Day') return e.durationDays == 1;
                      if (_selectedDuration == '2–4 Days') return e.durationDays >= 2 && e.durationDays <= 4;
                      if (_selectedDuration == '5–7 Days') return e.durationDays >= 5 && e.durationDays <= 7;
                      if (_selectedDuration == '8+ Days') return e.durationDays >= 8;
                      return true;
                    }).toList();
                  }
                  if (_selectedPriceRange != 'All') {
                    list = list.where((e) {
                      if (_selectedPriceRange == 'Under ₹5k') return e.price <= 5000;
                      if (_selectedPriceRange == '₹5k – ₹15k') return e.price > 5000 && e.price <= 15000;
                      if (_selectedPriceRange == '₹15k – ₹30k') return e.price > 15000 && e.price <= 30000;
                      if (_selectedPriceRange == '₹30k+') return e.price > 30000;
                      return true;
                    }).toList();
                  }
                  if (_searchController.text.trim().isNotEmpty) {
                    final q = _searchController.text.trim().toLowerCase();
                    list = list.where((e) =>
                        e.title.toLowerCase().contains(q) ||
                        e.city.toLowerCase().contains(q) ||
                        e.state.toLowerCase().contains(q) ||
                        e.guideName.toLowerCase().contains(q) ||
                        e.description.toLowerCase().contains(q)).toList();
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
