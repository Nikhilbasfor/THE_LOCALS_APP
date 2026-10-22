import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/spring_interactions.dart';
import '../role_selection_screen.dart';
import 'guide_dashboard_tab.dart';
import 'guide_experiences_tab.dart';
import 'guide_bookings_tab.dart';
import 'guide_profile_tab.dart';
import 'guide_notification_bell.dart';
import 'guide_onboarding_screen.dart';

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
    final user = _authRepo.currentUser;
    final uid = user?.uid ?? '';

    return StreamBuilder<UserModel?>(
      stream: _authRepo.getUserStream(uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting && userSnapshot.data == null) {
          return const Scaffold(
            backgroundColor: AppColors.bgLight,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.headerNavy),
            ),
          );
        }

        final userModel = userSnapshot.data;

        // Requirement 14: Keep host content locked until admin approves
        // If guide is not approved yet, show the Document Under Review page directly
        if (userModel != null && !userModel.verified) {
          return GuideOnboardingScreen(
            initialUser: userModel,
            initialStep: 5,
          );
        }

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
              selectedItemColor: AppColors.headerNavy,
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
                  label: 'Experiences',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.confirmation_number_outlined),
                  activeIcon: const Icon(Icons.confirmation_number).springPop(),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outlined),
                  activeIcon: const Icon(Icons.person).springPop(),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
