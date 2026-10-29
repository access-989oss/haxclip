import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/hax_theme.dart';

class Hax3dText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;
  final Color primaryColor;
  final Color accentColor;

  const Hax3dText({
    super.key,
    required this.text,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 2.0,
    this.textAlign = TextAlign.center,
    this.primaryColor = HaxTheme.neonCyan,
    this.accentColor = HaxTheme.neonViolet,
  });

  @override
  State<Hax3dText> createState() => _Hax3dTextState();
}

class _Hax3dTextState extends State<Hax3dText>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final progress = _animController.value * 2 * math.pi;
        final chromaticOffsetX = math.sin(progress) * 2.2;
        final chromaticOffsetY = math.cos(progress) * 1.5;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Red/Violet Chromatic Aberration Shadow Layer (Left/Up)
            Transform.translate(
              offset: Offset(-chromaticOffsetX, -chromaticOffsetY),
              child: Text(
                widget.text,
                textAlign: widget.textAlign,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  letterSpacing: widget.letterSpacing,
                  color: widget.accentColor.withOpacity(0.65),
                ),
              ),
            ),

            // 2. Cyan Chromatic Aberration Layer (Right/Down)
            Transform.translate(
              offset: Offset(chromaticOffsetX, chromaticOffsetY),
              child: Text(
                widget.text,
                textAlign: widget.textAlign,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  letterSpacing: widget.letterSpacing,
                  color: widget.primaryColor.withOpacity(0.65),
                ),
              ),
            ),

            // 3. Crisp Foreground 3D Embossed White Text with Glow
            Text(
              widget.text,
              textAlign: widget.textAlign,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                letterSpacing: widget.letterSpacing,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: widget.primaryColor.withOpacity(0.9),
                    blurRadius: 16,
                  ),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
