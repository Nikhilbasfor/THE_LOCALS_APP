import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
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

    return StreamBuilder<UserModel?>(
      stream: _authRepo.getUserStream(uid),
      builder: (context, userSnapshot) {
        final userModel = userSnapshot.data;
        final isVerified = userModel?.verified ?? true; // Default true if stream loading to prevent flash
        final rejectionReason = userModel?.rejectionReason;
        final isRevoked = userModel != null && !isVerified;

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
          body: Column(
            children: [
              // REAL-TIME ADMIN REVOCATION ALERT BANNER
              if (isRevoked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border(bottom: BorderSide(color: AppColors.brandRed.withValues(alpha: 0.3), width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gavel_rounded, color: AppColors.brandRed, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'APPROVAL REVOKED / REVISION REQUIRED',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandRed, fontSize: 12, letterSpacing: 0.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Admin has paused your approval until requirements are updated.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Click to Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GuideOnboardingScreen(
                                    initialUser: userModel,
                                    initialStep: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'Admin Feedback: $rejectionReason',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _currentIdx,
                  children: tabs,
                ),
              ),
            ],
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
      },
    );
  }
}
