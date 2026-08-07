import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import 'role_selection_screen.dart';
import 'guide/guide_main_screen.dart';
import 'guide/guide_onboarding_screen.dart';
import 'traveller/traveller_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // Not logged in — go to role selection
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        return;
      }

      // Logged in — fetch user role from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (!doc.exists || doc.data() == null) {
          // Firestore profile missing — go to role selection
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
          return;
        }

        final userModel = UserModel.fromMap(doc.data()!, doc.id);

        if (userModel.role == 'guide') {
          if (userModel.verified) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GuideMainScreen()),
            );
          } else {
            // Guide needs onboarding or verification review
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => GuideOnboardingScreen(
                  initialUser: userModel,
                  initialStep: userModel.onboardingComplete ? 5 : 1,
                ),
              ),
            );
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TravellerMainScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerNavy,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'THE LOCALS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authentic Local Experiences',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.cyanAccent.shade100,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
