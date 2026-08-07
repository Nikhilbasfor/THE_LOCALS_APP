import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'traveller_dashboard_tab.dart';
import 'explore_home_screen.dart';
import 'traveller_bookings_tab.dart';
import 'traveller_profile_tab.dart';

class TravellerMainScreen extends StatefulWidget {
  const TravellerMainScreen({super.key});

  @override
  State<TravellerMainScreen> createState() => _TravellerMainScreenState();
}

class _TravellerMainScreenState extends State<TravellerMainScreen> {
  int _currentIdx = 0;

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIdx,
        selectedItemColor: AppColors.travellerForestDark,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIdx = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
