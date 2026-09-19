import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A cinematic, living backdrop featuring a slow-pan Ken Burns camera movement
/// across lush green mountain ridges with frosted glassmorphism overlays.
/// Creates a bespoke, premium first impression for authentication and role selection.
class CinematicScenicBackground extends StatefulWidget {
  final Widget child;
  final String imageUrl;
  final double overlayAlpha;

  const CinematicScenicBackground({
    super.key,
    required this.child,
    this.imageUrl = 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1600&q=85',
    this.overlayAlpha = 0.55,
  });

  @override
  State<CinematicScenicBackground> createState() => _CinematicScenicBackgroundState();
}

class _CinematicScenicBackgroundState extends State<CinematicScenicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _panController;

  @override
  void initState() {
    super.initState();
    _panController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Moving Ken Burns Photographic Backdrop
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _panController,
            builder: (context, child) {
              // Smooth sinusoidal panning & subtle zoom
              final double t = _panController.value;
              final double scale = 1.14 + (0.08 * math.sin(t * math.pi));
              final double translateX = (t - 0.5) * 38;
              final double translateY = (math.sin(t * 2 * math.pi)) * 12;

              return Transform.translate(
                offset: Offset(translateX, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF0C1F17),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F261C), Color(0xFF14382B), Color(0xFF0B1914)],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Ambient Dark Glassmorphic Gradients
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: widget.overlayAlpha * 0.7),
                  Colors.black.withValues(alpha: widget.overlayAlpha * 0.4),
                  Colors.black.withValues(alpha: widget.overlayAlpha * 0.92),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Gentle emerald mist tint
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.2),
                radius: 1.1,
                colors: [
                  const Color(0xFF0D9488).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Foreground Content
        widget.child,
      ],
    );
  }
}
