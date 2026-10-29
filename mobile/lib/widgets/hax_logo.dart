import 'package:flutter/material.dart';

class HaxLogo extends StatelessWidget {
  final double size;
  final bool animate;

  const HaxLogo({
    super.key,
    this.size = 48.0,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00E5FF), // Electric Cyan
            Color(0xFF7C3AED), // Deep Violet
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            spreadRadius: 1,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.6, size * 0.6),
          painter: _HaxLogoPainter(),
        ),
      ),
    );
  }
}

class _HaxLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw stylized sleek 'H' with film/scissors notch
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.22;

    // Left bar
    final leftRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, stroke, h),
      Radius.circular(stroke * 0.4),
    );
    canvas.drawRRect(leftRRect, paint);

    // Right bar
    final rightRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - stroke, 0, stroke, h),
      Radius.circular(stroke * 0.4),
    );
    canvas.drawRRect(rightRRect, paint);

    // Center connecting bridge with angled cut (clipping aesthetic)
    final bridgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bridgePath = Path()
      ..moveTo(stroke * 0.8, h * 0.40)
      ..lineTo(w - stroke * 0.8, h * 0.48)
      ..lineTo(w - stroke * 0.8, h * 0.60)
      ..lineTo(stroke * 0.8, h * 0.52)
      ..close();
    canvas.drawPath(bridgePath, bridgePaint);

    // Play/Clip triangle highlight in cyan
    final playPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    final playPath = Path()
      ..moveTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.62, h * 0.50)
      ..lineTo(w * 0.42, h * 0.62)
      ..close();
    canvas.drawPath(playPath, playPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
