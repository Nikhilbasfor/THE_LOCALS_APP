import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A bespoke textured background with calm, subtle watermarks of travel iconography
/// (mountain peaks, compass rose, pine trees, hiking paths, tents, and pins).
/// Adds texture and warmth so the canvas never feels like an empty blank void.
class TravelPatternBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double patternOpacity;

  const TravelPatternBackground({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.bgLight,
    this.patternOpacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: CustomPaint(
        painter: _TravelPatternPainter(
          opacity: patternOpacity,
          tintColor: AppColors.travellerForestDark,
        ),
        child: child,
      ),
    );
  }
}

class _TravelPatternPainter extends CustomPainter {
  final double opacity;
  final Color tintColor;

  _TravelPatternPainter({required this.opacity, required this.tintColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = tintColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = tintColor.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.fill;

    const double stepX = 140.0;
    const double stepY = 140.0;

    int colIndex = 0;
    for (double y = 20; y < size.height + 60; y += stepY) {
      int rowIndex = 0;
      final double offsetX = (colIndex % 2 == 1) ? 70.0 : 0.0;
      for (double x = -30 + offsetX; x < size.width + 60; x += stepX) {
        final int symbolType = (rowIndex + colIndex) % 5;
        canvas.save();
        canvas.translate(x, y);

        switch (symbolType) {
          case 0:
            _drawMountain(canvas, strokePaint);
            break;
          case 1:
            _drawCompass(canvas, strokePaint, fillPaint);
            break;
          case 2:
            _drawPineTree(canvas, strokePaint);
            break;
          case 3:
            _drawTent(canvas, strokePaint);
            break;
          case 4:
            _drawWaypoint(canvas, strokePaint, fillPaint);
            break;
        }

        canvas.restore();
        rowIndex++;
      }
      colIndex++;
    }
  }

  void _drawMountain(Canvas canvas, Paint stroke) {
    final path = Path();
    // Big mountain
    path.moveTo(-18, 12);
    path.lineTo(-2, -14);
    path.lineTo(14, 12);
    path.close();
    // Ridge line
    path.moveTo(-2, -14);
    path.lineTo(2, 12);
    // Smaller secondary mountain
    path.moveTo(6, 12);
    path.lineTo(16, -2);
    path.lineTo(26, 12);
    canvas.drawPath(path, stroke);
  }

  void _drawCompass(Canvas canvas, Paint stroke, Paint fill) {
    // Outer circle
    canvas.drawCircle(Offset.zero, 13, stroke);
    // 4-point star
    final star = Path()
      ..moveTo(0, -11)
      ..lineTo(3, -3)
      ..lineTo(11, 0)
      ..lineTo(3, 3)
      ..lineTo(0, 11)
      ..lineTo(-3, 3)
      ..lineTo(-11, 0)
      ..lineTo(-3, -3)
      ..close();
    canvas.drawPath(star, fill);
  }

  void _drawPineTree(Canvas canvas, Paint stroke) {
    final path = Path();
    // Trunk
    path.moveTo(0, 8);
    path.lineTo(0, 14);
    // Tier 1
    path.moveTo(0, -14);
    path.lineTo(7, -6);
    path.lineTo(4, -6);
    // Tier 2
    path.lineTo(9, 2);
    path.lineTo(6, 2);
    // Tier 3
    path.lineTo(11, 9);
    path.lineTo(-11, 9);
    path.lineTo(-6, 2);
    path.lineTo(-9, 2);
    path.lineTo(-4, -6);
    path.lineTo(-7, -6);
    path.close();
    canvas.drawPath(path, stroke);
  }

  void _drawTent(Canvas canvas, Paint stroke) {
    final path = Path();
    path.moveTo(-14, 10);
    path.lineTo(0, -12);
    path.lineTo(14, 10);
    path.close();
    // Tent flap
    path.moveTo(0, -12);
    path.lineTo(4, 10);
    // Guyline
    path.moveTo(-14, 10);
    path.lineTo(-18, 12);
    path.moveTo(14, 10);
    path.lineTo(18, 12);
    canvas.drawPath(path, stroke);
  }

  void _drawWaypoint(Canvas canvas, Paint stroke, Paint fill) {
    // Map pin
    final path = Path();
    path.moveTo(0, 12);
    path.quadraticBezierTo(-10, 0, -10, -5);
    path.arcTo(
      Rect.fromCircle(center: const Offset(0, -5), radius: 10),
      math.pi,
      math.pi,
      false,
    );
    path.quadraticBezierTo(10, 0, 0, 12);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(const Offset(0, -5), 3.5, fill);
  }

  @override
  bool shouldRepaint(covariant _TravelPatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.tintColor != tintColor;
  }
}
