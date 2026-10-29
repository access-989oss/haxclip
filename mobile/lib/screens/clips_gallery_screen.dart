import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../theme/hax_theme.dart';
import '../widgets/clip_card_3d.dart';
import '../widgets/hax_3d_background.dart';
import '../widgets/hax_3d_tilt_card.dart';

class ClipsGalleryScreen extends StatefulWidget {
  final String? taskId;

  const ClipsGalleryScreen({super.key, this.taskId});

  @override
  State<ClipsGalleryScreen> createState() => _ClipsGalleryScreenState();
}

class _ClipsGalleryScreenState extends State<ClipsGalleryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  TaskModel? _currentTask;
  List<TaskModel> _allTasks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.taskId != null) {
        final task = await _apiService.getTask(widget.taskId!);
        if (mounted) {
          setState(() {
            _currentTask = task;
            _isLoading = false;
          });
        }
      } else {
        final tasks = await _apiService.listTasks();
        if (mounted) {
          setState(() {
            _allTasks = tasks;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingleTask = widget.taskId != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isSingleTask ? 'GENERATED CLIPS' : 'YOUR CLIPS LIBRARY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: HaxTheme.neonCyan),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Hax3dBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: HaxTheme.neonCyan),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: HaxTheme.neonRose, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : isSingleTask
                      ? _buildClipsList(_currentTask!)
                      : _buildTasksList(_allTasks),
        ),
      ),
    );
  }

  Widget _buildClipsList(TaskModel task) {
    final clips = task.clips;

    if (clips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, color: HaxTheme.neonCyan, size: 54),
            const SizedBox(height: 16),
            const Text(
              'No clips found for this task.',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Task status: ${task.status}',
              style: const TextStyle(color: HaxTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: HaxTheme.neonCyan,
      backgroundColor: const Color(0xFF151530),
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: clips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header Stats Banner
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x99151530),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x3300F0FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: HaxTheme.neonCyan, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${clips.length} Viral Shorts Extracted',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.sourceTitle ?? 'Source Video',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: HaxTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final clip = clips[index - 1];
          return ClipCard3d(clip: clip, taskId: task.id);
        },
      ),
    );
  }

  Widget _buildTasksList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_collection_outlined, color: HaxTheme.neonViolet, size: 60),
            const SizedBox(height: 16),
            const Text(
              'No previous tasks found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first clip on the home screen!',
              style: TextStyle(color: HaxTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: HaxTheme.neonCyan,
      backgroundColor: const Color(0xFF151530),
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = tasks[index];

          return Hax3dTiltCard(
            glowColor: t.isCompleted ? HaxTheme.neonGreen : HaxTheme.neonCyan,
            padding: const EdgeInsets.all(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClipsGalleryScreen(taskId: t.id),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (t.isCompleted ? HaxTheme.neonGreen : HaxTheme.neonCyan).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    t.isCompleted ? Icons.check_circle : Icons.sync,
                    color: t.isCompleted ? HaxTheme.neonGreen : HaxTheme.neonCyan,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.sourceTitle ?? 'Task ${t.id.substring(0, 8)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.clipsCount} clips • Status: ${t.status}',
                        style: const TextStyle(color: HaxTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          );
        },
      ),
    );
  }
}
