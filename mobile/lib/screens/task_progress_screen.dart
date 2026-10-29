import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../theme/hax_theme.dart';
import '../widgets/hax_3d_background.dart';
import '../widgets/hax_3d_button.dart';
import '../widgets/hax_3d_tilt_card.dart';
import 'clips_gallery_screen.dart';

class TaskProgressScreen extends StatefulWidget {
  final String taskId;
  final String? videoTitle;

  const TaskProgressScreen({
    super.key,
    required this.taskId,
    this.videoTitle,
  });

  @override
  State<TaskProgressScreen> createState() => _TaskProgressScreenState();
}

class _TaskProgressScreenState extends State<TaskProgressScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;
  TaskModel? _currentTask;
  String _error = '';
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _checkStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    try {
      final task = await _apiService.getTask(widget.taskId);
      if (mounted) {
        setState(() {
          _currentTask = task;
        });

        if (task.isCompleted) {
          _pollingTimer?.cancel();
        } else if (task.isFailed) {
          _pollingTimer?.cancel();
          setState(() {
            _error = task.errorMessage ?? 'VPS AI Processing failed';
          });
        }
      }
    } catch (e) {
      // Don't kill polling on transient network hiccup
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    final progress = task?.progress ?? 0.05;
    final isDone = task?.isCompleted ?? false;
    final isFailed = task?.isFailed ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('PROCESSING PIPELINE'),
      ),
      body: Hax3dBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Video Title
                Text(
                  widget.videoTitle ?? 'Video Clipping Task',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Task ID: ${widget.taskId}',
                  style: const TextStyle(color: HaxTheme.textMuted, fontSize: 11),
                ),

                const Spacer(),

                // 3D Animated Progress Radar Core
                _build3dRadarCore(progress, isDone, isFailed),

                const Spacer(),

                // Status Card
                Hax3dTiltCard(
                  glowColor: isDone
                      ? HaxTheme.neonGreen
                      : (isFailed ? HaxTheme.neonRose : HaxTheme.neonCyan),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // Current stage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : (isFailed ? Icons.error_rounded : Icons.sync_rounded),
                            color: isDone
                                ? HaxTheme.neonGreen
                                : (isFailed ? HaxTheme.neonRose : HaxTheme.neonCyan),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isDone
                                  ? 'CLIPPING COMPLETE! (${task?.clips.length ?? 0} Clips Ready)'
                                  : (isFailed
                                      ? 'ERROR OCCURRED'
                                      : (task?.currentStage ?? 'Analyzing video & audio stream...')),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDone
                                    ? HaxTheme.neonGreen
                                    : (isFailed ? HaxTheme.neonRose : Colors.white),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: HaxTheme.neonRose, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Step Indicators
                      _buildStepRow(
                        1,
                        'Speech Transcription',
                        'AssemblyAI neural audio analysis',
                        progress >= 0.25 || isDone,
                      ),
                      const SizedBox(height: 8),
                      _buildStepRow(
                        2,
                        'Viral Hook Selection',
                        'Gemini Flash AI highlights & virality scoring',
                        progress >= 0.65 || isDone,
                      ),
                      const SizedBox(height: 8),
                      _buildStepRow(
                        3,
                        'FFmpeg 3D Video Rendering',
                        'Cropping, styling & burning dynamic subtitles',
                        isDone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Button to view clips if done
                if (isDone)
                  Hax3dButton(
                    text: 'VIEW ${task?.clips.length ?? 0} VIRAL CLIPS',
                    icon: Icons.movie_filter_rounded,
                    primaryColor: HaxTheme.neonGreen,
                    textColor: Colors.black,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ClipsGalleryScreen(taskId: widget.taskId),
                        ),
                      );
                    },
                  )
                else if (isFailed)
                  Hax3dButton(
                    text: 'BACK TO HOME',
                    icon: Icons.arrow_back,
                    primaryColor: HaxTheme.neonRose,
                    textColor: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  const Text(
                    '⚡ Processing asynchronously on VPS. You can close or wait.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HaxTheme.textMuted, fontSize: 12),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3dRadarCore(double progress, bool isDone, bool isFailed) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, _) {
        final rot = _radarController.value * 2 * math.pi;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating neon cyan hex ring
            Transform.rotate(
              angle: rot,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? HaxTheme.neonGreen.withOpacity(0.4)
                        : HaxTheme.neonCyan.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDone
                          ? HaxTheme.neonGreen.withOpacity(0.2)
                          : HaxTheme.neonCyan.withOpacity(0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            // Middle counter-rotating dashed ring
            Transform.rotate(
              angle: -rot * 1.5,
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HaxTheme.neonViolet.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Inner Center Core
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDone
                        ? const Color(0xFF10B981)
                        : const Color(0xFF00F0FF),
                    const Color(0xFF0F0F26),
                  ],
                  stops: const [0.2, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDone ? HaxTheme.neonGreen : HaxTheme.neonCyan).withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 54)
                    : (isFailed
                        ? const Icon(Icons.close_rounded, color: Colors.white, size: 54)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'PROCESSING',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          )),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepRow(int number, String title, String subtitle, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? HaxTheme.neonGreen : const Color(0x33FFFFFF),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.black)
                : Text('$number', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isCompleted ? Colors.white : HaxTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: HaxTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
