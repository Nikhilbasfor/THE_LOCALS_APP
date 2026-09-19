import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/cinematic_scenic_background.dart';
import '../widgets/spring_interactions.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CinematicScenicBackground(
        // High-res lush mountain landscape photography with slow-pan camera motion
        imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1600&q=85',
        overlayAlpha: 0.60,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),

                // App Branding with Glowing Ring
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 68,
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ).springPop(delayMs: 150),
                const SizedBox(height: 18),

                const Text(
                  'THE LOCALS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3.5,
                  ),
                ).staggeredEntrance(index: 1),
                const SizedBox(height: 6),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'CHOOSE YOUR PORTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6EE7B7),
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ).staggeredEntrance(index: 2),

                const Spacer(flex: 2),

                // Frosted Glassmorphism Traveller Role Card
                _GlassRoleCard(
                  title: 'Book an experience',
                  subtitle: 'Discover authentic guided expeditions, hidden valleys & verified local hosts',
                  badge: 'EXPLORE',
                  icon: Icons.backpack_outlined,
                  accentColor: const Color(0xFF38BDF8),
                  gradientColors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.55),
                    const Color(0xFF0C4A6E).withValues(alpha: 0.75),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(role: 'traveller'),
                      ),
                    );
                  },
                ).staggeredEntrance(index: 3),
                const SizedBox(height: 18),

                // Frosted Glassmorphism Guide Role Card
                _GlassRoleCard(
                  title: 'Host an experience',
                  subtitle: 'Create itineraries, host expeditions & lead travellers through your homeland',
                  badge: 'HOST & GUIDE',
                  icon: Icons.nature_people_outlined,
                  accentColor: const Color(0xFF34D399),
                  gradientColors: [
                    const Color(0xFF059669).withValues(alpha: 0.55),
                    const Color(0xFF064E3B).withValues(alpha: 0.75),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(role: 'guide'),
                      ),
                    );
                  },
                ).staggeredEntrance(index: 4),

                const Spacer(flex: 2),

                // Signature brand pillars footer
                Text(
                  'Offbeat ★ Immersive ★ Sustainable ★ Travel and Learn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 1.1,
                  ),
                ).staggeredEntrance(index: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassRoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GlassRoleCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTapFeedback(
      onTap: onTap,
      scaleDown: 0.965,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
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
