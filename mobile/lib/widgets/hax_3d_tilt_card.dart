import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/hax_theme.dart';

class Hax3dTiltCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color glowColor;
  final VoidCallback? onTap;

  const Hax3dTiltCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
    this.glowColor = HaxTheme.neonCyan,
    this.onTap,
  });

  @override
  State<Hax3dTiltCard> createState() => _Hax3dTiltCardState();
}

class _Hax3dTiltCardState extends State<Hax3dTiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;
  double _touchTiltX = 0.0;
  double _touchTiltY = 0.0;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _isInteracting = true;
      // Map touch offset to [-1, 1] range
      final dx = (details.localPosition.dx / size.width) * 2 - 1;
      final dy = (details.localPosition.dy / size.height) * 2 - 1;
      _touchTiltY = dx.clamp(-1.0, 1.0) * 0.22; // rotate around Y axis
      _touchTiltX = -dy.clamp(-1.0, 1.0) * 0.22; // rotate around X axis
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isInteracting = false;
      _touchTiltX = 0.0;
      _touchTiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final animProgress = _ambientController.value * 2 * math.pi;
        // Continuous organic 3D breathing tilt
        final ambientTiltX = math.sin(animProgress) * 0.045;
        final ambientTiltY = math.cos(animProgress * 0.8) * 0.055;

        final finalTiltX = _isInteracting ? _touchTiltX : ambientTiltX;
        final finalTiltY = _isInteracting ? _touchTiltY : ambientTiltY;

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              onTap: widget.onTap,
              onPanUpdate: (d) => _onPanUpdate(d, cardSize),
              onPanEnd: _onPanEnd,
              onPanCancel: () => setState(() => _isInteracting = false),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // 3D Perspective focal length
                  ..rotateX(finalTiltX)
                  ..rotateY(finalTiltY),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: const Color(0xE6101026),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: widget.glowColor.withOpacity(0.35 + math.sin(animProgress).abs() * 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withOpacity(0.18 + math.sin(animProgress).abs() * 0.12),
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: Offset(finalTiltY * 40, 12 - finalTiltX * 30),
                      ),
                      const BoxShadow(
                        color: Color(0x99000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + finalTiltY * 2, -1.0 - finalTiltX * 2),
                      end: Alignment(1.0 + finalTiltY * 2, 1.0 - finalTiltX * 2),
                      colors: [
                        Colors.white.withOpacity(0.08),
                        const Color(0x00FFFFFF),
                        widget.glowColor.withOpacity(0.04),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
