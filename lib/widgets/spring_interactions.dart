import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Tactile spring physics wrapper that compresses on press and bounces on release.
class SpringTapFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve releaseCurve;
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const SpringTapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.97,
    this.pressDuration = const Duration(milliseconds: 100),
    this.releaseDuration = const Duration(milliseconds: 250),
    this.releaseCurve = Curves.easeOutBack,
    this.enableHaptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<SpringTapFeedback> createState() => _SpringTapFeedbackState();
}

class _SpringTapFeedbackState extends State<SpringTapFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.releaseDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: widget.releaseCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _isPressed = true;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.animateTo(
      1.0,
      duration: widget.pressDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.animateBack(
      0.0,
      duration: widget.releaseDuration,
      curve: widget.releaseCurve,
    );
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.animateBack(
      0.0,
      duration: widget.releaseDuration,
      curve: widget.releaseCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.center,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A bespoke, human-crafted card widget with spring tactile response,
/// soft borders, and smooth elevation.
class SpringCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final double scaleDown;

  const SpringCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.borderRadius = 16.0,
    this.border,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.scaleDown = 0.975,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6), width: 1),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap == null && onLongPress == null) {
      return cardContent;
    }

    return SpringTapFeedback(
      onTap: onTap,
      onLongPress: onLongPress,
      scaleDown: scaleDown,
      child: cardContent,
    );
  }
}

/// A spring-animated button designed for high tactile satisfaction.
class BouncingButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;
  final double? height;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final bool isLoading;

  const BouncingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor = AppColors.travellerForestDark,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.borderRadius = 14.0,
    this.width,
    this.height,
    this.border,
    this.boxShadow,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTapFeedback(
      onTap: isLoading ? null : onPressed,
      scaleDown: 0.95,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: onPressed == null
              ? backgroundColor.withValues(alpha: 0.5)
              : backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

/// Extensions on Widget for effortless bespoke staggered cascades with flutter_animate
extension BespokeAnimationExtensions on Widget {
  /// Staggered slide and fade-in cascade for lists and grids.
  Widget staggeredEntrance({
    int index = 0,
    int baseDelayMs = 45,
    int durationMs = 400,
    double slideOffset = 0.12,
  }) {
    return animate(delay: (index * baseDelayMs).ms)
        .fadeIn(
          duration: durationMs.ms,
          curve: Curves.easeOutQuad,
        )
        .slideY(
          begin: slideOffset,
          end: 0,
          duration: durationMs.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Gentle spring pop-in for badges, headers, and highlights.
  Widget springPop({
    int delayMs = 0,
    int durationMs = 450,
  }) {
    return animate(delay: delayMs.ms)
        .fadeIn(duration: (durationMs * 0.7).round().ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          duration: durationMs.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// Global standard bouncing scroll physics for iOS/smooth overscroll feel
const BouncingScrollPhysics bespokeBouncingScrollPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
