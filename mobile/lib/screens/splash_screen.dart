import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/hax_theme.dart';
import '../widgets/hax_logo.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _statusText = 'Initializing HaxClip...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _checkBackendAndProceed();
  }

  Future<void> _checkBackendAndProceed() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _statusText = 'Connecting to VPS Backend...');

    final api = ApiService();
    final healthy = await api.checkHealth();

    if (mounted) {
      setState(() {
        _isConnected = healthy;
        _statusText = healthy ? 'VPS Backend Connected' : 'Ready (Offline / Checking)';
      });
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaxTheme.bgPrimary,
      body: Stack(
        children: [
          // Subtle radial background glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HaxTheme.cyanAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main splash content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HaxLogo(size: 88),
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Video Repurposing Studio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: HaxTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading dot indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected
                                ? HaxTheme.emeraldAccent
                                : HaxTheme.cyanAccent,
                            boxShadow: [
                              BoxShadow(
                                color: (_isConnected
                                        ? HaxTheme.emeraldAccent
                                        : HaxTheme.cyanAccent)
                                    .withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: HaxTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer version
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0 • Powered by VPS & FFmpeg',
                style: TextStyle(
                  fontSize: 11,
                  color: HaxTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
