import 'package:flutter/material.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../role_selection_screen.dart';
import 'guide_dashboard_tab.dart';
import 'guide_experiences_tab.dart';
import 'guide_bookings_tab.dart';
import 'guide_profile_tab.dart';
import 'guide_notification_bell.dart';

class GuideMainScreen extends StatefulWidget {
  const GuideMainScreen({super.key});

  @override
  State<GuideMainScreen> createState() => _GuideMainScreenState();
}

class _GuideMainScreenState extends State<GuideMainScreen> {
  final AuthRepository _authRepo = AuthRepository();
  int _currentIdx = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      GuideDashboardTab(
        onNavigateToTab: (idx) {
          setState(() => _currentIdx = idx);
        },
      ),
      const GuideExperiencesTab(),
      const GuideBookingsTab(),
      GuideProfileTab(
        onNavigateToTab: (idx) {
          setState(() => _currentIdx = idx);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
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
            const SizedBox(width: 10),
            Text(
              _currentIdx == 0
                  ? 'THE LOCALS · Guide'
                  : _currentIdx == 1
                      ? 'THE LOCALS · Experiences'
                      : _currentIdx == 2
                          ? 'THE LOCALS · Bookings'
                          : 'THE LOCALS · Profile',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ],
        ),
        actions: [
          GuideNotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await _authRepo.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIdx,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIdx,
        onTap: (idx) => setState(() => _currentIdx = idx),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.headerNavy,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Experiences',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
