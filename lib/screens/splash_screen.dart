import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'role_selection_screen.dart';
import 'guide/guide_main_screen.dart';
import 'guide/guide_onboarding_screen.dart';
import 'traveller/traveller_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Spring controller for logo popping up from bottom to center
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 3.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _springController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _springController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _springController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _springController.forward();

    // Routing evaluation after splash presentation
    Future.delayed(const Duration(milliseconds: 2700), () async {
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _navigate(const RoleSelectionScreen());
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (!doc.exists || doc.data() == null) {
          await FirebaseAuth.instance.signOut();
          _navigate(const RoleSelectionScreen());
          return;
        }

        final userModel = UserModel.fromMap(doc.data()!, doc.id);

        if (userModel.role == 'guide') {
          final isEmailVerified = currentUser.emailVerified;
          if (!userModel.onboardingComplete) {
            _navigate(
              GuideOnboardingScreen(
                initialUser: userModel,
                initialStep: isEmailVerified ? 1 : 0,
              ),
            );
          } else if (!userModel.verified) {
            _navigate(
              GuideOnboardingScreen(
                initialUser: userModel,
                initialStep: 5,
              ),
            );
          } else {
            _navigate(const GuideMainScreen());
          }
        } else {
          _navigate(const TravellerMainScreen());
        }
      } catch (e) {
        if (!mounted) return;
        _navigate(const RoleSelectionScreen());
      }
    });
  }

  void _navigate(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Deep Midnight Blue Radial Backdrop
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Color(0xFF0F2042),
                    Color(0xFF0A1224),
                    Color(0xFF030712),
                  ],
                ),
              ),
            ),
          ),

          // Central Logo Popping from Bottom to Center & Brand Entrance
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SlideTransition(
                    position: _logoSlideAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Brand text & tagline fading and springing smoothly
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'THE LOCALS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'Unique, Handcrafted & Immersive experiences around the world',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBAE6FD),
                              letterSpacing: 0.8,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
