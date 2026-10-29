import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/hax_theme.dart';

class Hax3dButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color primaryColor;
  final Color textColor;
  final double height;
  final double? width;

  const Hax3dButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.primaryColor = HaxTheme.neonCyan,
    this.textColor = Colors.black,
    this.height = 56,
    this.width,
  });

  @override
  State<Hax3dButton> createState() => _Hax3dButtonState();
}

class _Hax3dButtonState extends State<Hax3dButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double extrusionHeight = 5.0;
    final double currentOffset = _isPressed ? extrusionHeight : 0.0;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glowProgress = _glowController.value;
        final pulseAlpha = 0.35 + math.sin(glowProgress * 2 * math.pi).abs() * 0.45;

        return SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height + extrusionHeight,
          child: GestureDetector(
            onTapDown: widget.onPressed == null || widget.isLoading
                ? null
                : (_) => setState(() => _isPressed = true),
            onTapUp: widget.onPressed == null || widget.isLoading
                ? null
                : (_) {
                    setState(() => _isPressed = false);
                    widget.onPressed!();
                  },
            onTapCancel: () => setState(() => _isPressed = false),
            child: Stack(
              children: [
                // 1. Bottom 3D Extrusion Bevel Base
                Positioned(
                  top: extrusionHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.lerp(widget.primaryColor, Colors.black, 0.55),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(pulseAlpha * 0.7),
                          blurRadius: _isPressed ? 12 : 22,
                          spreadRadius: _isPressed ? 0 : 2,
                          offset: Offset(0, _isPressed ? 4 : 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Tactile Moving Face
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 70),
                  curve: Curves.easeOut,
                  top: currentOffset,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primaryColor,
                          Color.lerp(widget.primaryColor, Colors.white, 0.25)!,
                          Color.lerp(widget.primaryColor, Colors.black, 0.15)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.8,
                                color: widget.textColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color: widget.textColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  widget.text,
                                  style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
