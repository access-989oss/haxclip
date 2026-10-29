import 'dart:math' as math;
import 'package:flutter/material.dart';

class Hax3dBackground extends StatefulWidget {
  final Widget? child;

  const Hax3dBackground({super.key, this.child});

  @override
  State<Hax3dBackground> createState() => _Hax3dBackgroundState();
}

class _Hax3dBackgroundState extends State<Hax3dBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark background base
        Container(
          color: const Color(0xFF070712),
        ),
        // 3D Canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _Hax3dScenePainter(progress: _controller.value),
              );
            },
          ),
        ),
        // Content overlay
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Point3D {
  double x, y, z;
  _Point3D(this.x, this.y, this.z);

  _Point3D rotateX(double angle) {
    final rad = angle;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    return _Point3D(x, y * cosA - z * sinA, y * sinA + z * cosA);
  }

  _Point3D rotateY(double angle) {
    final rad = angle;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    return _Point3D(x * cosA + z * sinA, y, -x * sinA + z * cosA);
  }

  _Point3D rotateZ(double angle) {
    final rad = angle;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    return _Point3D(x * cosA - y * sinA, x * sinA + y * cosA, z);
  }

  Offset project(double width, double height, double fov, double distance) {
    final factor = fov / (distance + z);
    final px = x * factor + width / 2;
    final py = y * factor + height / 2;
    return Offset(px, py);
  }
}

class _Hax3dScenePainter extends CustomPainter {
  final double progress;

  _Hax3dScenePainter({required this.progress});

  // Base 3D Icosahedron Vertices
  static final double phi = (1.0 + math.sqrt(5.0)) / 2.0; // golden ratio
  static final List<_Point3D> _baseVertices = [
    _Point3D(-1, phi, 0),
    _Point3D(1, phi, 0),
    _Point3D(-1, -phi, 0),
    _Point3D(1, -phi, 0),
    _Point3D(0, -1, phi),
    _Point3D(0, 1, phi),
    _Point3D(0, -1, -phi),
    _Point3D(0, 1, -phi),
    _Point3D(phi, 0, -1),
    _Point3D(phi, 0, 1),
    _Point3D(-phi, 0, -1),
    _Point3D(-phi, 0, 1),
  ];

  static final List<List<int>> _edges = [
    [0, 11], [0, 5], [0, 1], [0, 7], [0, 10],
    [1, 5], [5, 11], [11, 10], [10, 7], [7, 1],
    [3, 9], [3, 4], [3, 2], [3, 6], [3, 8],
    [4, 9], [2, 4], [6, 2], [8, 6], [9, 8],
    [4, 5], [5, 9], [9, 1], [1, 8], [8, 7],
    [7, 6], [6, 10], [10, 2], [2, 11], [11, 4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final time = progress * 2 * math.pi;

    // 1. Draw Ambient Radial Nebulas
    final nebula1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x228B5CF6),
          const Color(0x008B5CF6),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.25, size.height * 0.2),
        radius: size.width * 0.7,
      ));
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.2), size.width * 0.7, nebula1Paint);

    final nebula2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x1F00F0FF),
          const Color(0x0000F0FF),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.7),
        radius: size.width * 0.8,
      ));
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), size.width * 0.8, nebula2Paint);

    // 2. Draw 3D Receding Horizon Grid
    _drawHorizonGrid(canvas, size, progress);

    // 3. Draw 3D Floating Particles
    _drawParticles(canvas, size, progress);

    // 4. Draw Rotating 3D Polyhedron in Background
    _drawPolyhedron(canvas, size, time);
  }

  void _drawHorizonGrid(Canvas canvas, Size size, double p) {
    final horizonY = size.height * 0.65;
    final gridPaint = Paint()
      ..strokeWidth = 1.0
      ..color = const Color(0x1800F0FF);

    // Vanishing point in the horizon
    final vp = Offset(size.width * 0.5, horizonY);

    // Receding horizontal lines (moving toward camera)
    const numH = 12;
    for (int i = 0; i < numH; i++) {
      final t = ((i / numH) + (p * 2) % 1.0) % 1.0;
      final y = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
      final alpha = (t * 0.25).clamp(0.0, 0.25);
      final hPaint = Paint()
        ..color = Color(0xFF00F0FF).withOpacity(alpha)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hPaint);
    }

    // Perspective vertical fan lines
    const numV = 16;
    for (int i = 0; i <= numV; i++) {
      final spread = (i - numV / 2) / (numV / 2);
      final bottomX = size.width * 0.5 + spread * size.width * 0.9;
      canvas.drawLine(vp, Offset(bottomX, size.height), gridPaint);
    }
  }

  void _drawParticles(Canvas canvas, Size size, double p) {
    const count = 35;
    for (int i = 0; i < count; i++) {
      final seed = (i * 137.5) % 1000;
      final speed = 0.2 + (seed % 5) * 0.15;
      final t = (p * speed + (i / count)) % 1.0;

      final x = (math.sin(i * 1.7 + p * 2) * 0.45 + 0.5) * size.width;
      final y = (1.0 - t) * size.height;
      final z = math.sin(i * 3.1 + p * 4);

      final radius = 1.2 + (z + 1) * 1.4;
      final alpha = (0.2 + (z + 1) * 0.25).clamp(0.1, 0.7);

      final isViolet = i % 2 == 0;
      final color = isViolet
          ? Color(0xFFA855F7).withOpacity(alpha)
          : Color(0xFF00F0FF).withOpacity(alpha);

      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawPolyhedron(Canvas canvas, Size size, double time) {
    // Center polyhedron slightly above center
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.38;
    final scale = size.width * 0.32;

    final rotX = time * 0.4;
    final rotY = time * 0.6;
    final rotZ = time * 0.25;

    // Rotate and project all vertices
    final projected = <Offset>[];
    final rotatedVertices = <_Point3D>[];

    for (final v in _baseVertices) {
      final scaled = _Point3D(v.x * scale, v.y * scale, v.z * scale);
      final r = scaled.rotateX(rotX).rotateY(rotY).rotateZ(rotZ);
      rotatedVertices.add(r);

      // Simple perspective
      final fov = 700.0;
      final distance = 800.0;
      final factor = fov / (distance + r.z);
      projected.add(Offset(centerX + r.x * factor, centerY + r.y * factor));
    }

    // Draw 3D Edges
    for (final edge in _edges) {
      final p1 = projected[edge[0]];
      final p2 = projected[edge[1]];

      final avgZ = (rotatedVertices[edge[0]].z + rotatedVertices[edge[1]].z) / 2;
      final depthFactor = ((avgZ + scale) / (2 * scale)).clamp(0.0, 1.0);

      final edgeColor = Color.lerp(
        const Color(0xFF8B5CF6),
        const Color(0xFF00F0FF),
        depthFactor,
      )!;

      final alpha = (0.12 + depthFactor * 0.28).clamp(0.08, 0.40);
      final edgePaint = Paint()
        ..color = edgeColor.withOpacity(alpha)
        ..strokeWidth = 1.0 + depthFactor * 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, edgePaint);
    }

    // Draw glowing vertices
    for (int i = 0; i < projected.length; i++) {
      final p = projected[i];
      final z = rotatedVertices[i].z;
      final depthFactor = ((z + scale) / (2 * scale)).clamp(0.0, 1.0);

      final nodePaint = Paint()
        ..color = const Color(0xFF00F0FF).withOpacity(0.3 + depthFactor * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(p, 2.5 + depthFactor * 2.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Hax3dScenePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
