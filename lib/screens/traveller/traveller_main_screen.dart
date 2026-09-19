import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import 'traveller_dashboard_tab.dart';
import 'explore_home_screen.dart';
import 'traveller_bookings_tab.dart';
import 'traveller_profile_tab.dart';

class TravellerMainScreen extends StatefulWidget {
  final int initialTab;

  const TravellerMainScreen({super.key, this.initialTab = 0});

  @override
  State<TravellerMainScreen> createState() => _TravellerMainScreenState();
}

class _TravellerMainScreenState extends State<TravellerMainScreen> {
  late int _currentIdx;

  @override
  void initState() {
    super.initState();
    _currentIdx = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TravellerDashboardTab(
        onNavigateTab: (targetIdx) {
          setState(() {
            _currentIdx = targetIdx;
          });
        },
      ),
      const ExploreHomeScreen(),
      TravellerBookingsTab(),
      TravellerProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIdx,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.cardBorder.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIdx,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.travellerForestDark,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          onTap: (idx) {
            if (_currentIdx != idx) {
              HapticFeedback.selectionClick();
              setState(() => _currentIdx = idx);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard).springPop(),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore).springPop(),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.confirmation_number_outlined),
              activeIcon: const Icon(Icons.confirmation_number).springPop(),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person).springPop(),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

