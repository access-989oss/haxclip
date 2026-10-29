import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/youtube_info_model.dart';
import '../services/api_service.dart';
import '../services/youtube_service.dart';
import '../theme/hax_theme.dart';
import '../widgets/hax_3d_background.dart';
import '../widgets/hax_3d_button.dart';
import '../widgets/hax_3d_text.dart';
import '../widgets/hax_3d_tilt_card.dart';
import '../widgets/hax_logo.dart';
import 'clips_gallery_screen.dart';
import 'settings_screen.dart';
import 'task_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final YouTubeService _ytService = YouTubeService();
  final ApiService _apiService = ApiService();

  bool _isYouTubeMode = true;
  bool _isFetchingDetails = false;
  YouTubeInfoModel? _ytInfo;
  File? _selectedLocalFile;

  // Options
  String _outputFormat = '9:16';
  String _clipLength = 'auto';
  bool _addSubtitles = true;

  // Action status
  bool _isStartingTask = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _urlController.dispose();
    _ytService.dispose();
    super.dispose();
  }

  Future<void> _fetchYouTubeMetadata(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    setState(() {
      _isFetchingDetails = true;
      _ytInfo = null;
    });

    final info = await _ytService.getVideoDetails(cleanUrl);

    if (mounted) {
      setState(() {
        _isFetchingDetails = false;
        _ytInfo = info;
      });

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2A1015),
            content: Text(
              'Could not read YouTube link. Please check the URL.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickLocalFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.video,
    );

    if (files.isNotEmpty && files.first.path != null) {
      setState(() {
        _selectedLocalFile = File(files.first.path!);
      });
    }
  }

  Future<void> _handleStartClipping() async {
    if (_isYouTubeMode && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a YouTube URL first')),
      );
      return;
    }

    if (!_isYouTubeMode && _selectedLocalFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file first')),
      );
      return;
    }

    setState(() {
      _isStartingTask = true;
      _statusMessage = 'Initializing processing pipeline...';
    });

    try {
      File uploadFile;
      String? sourceTitle;

      if (_isYouTubeMode) {
        final rawUrl = _urlController.text.trim();
        sourceTitle = _ytInfo?.title ?? 'YouTube Video';

        // 1. Download stream directly on device (bypassing VPS datacenter IP block!)
        uploadFile = await _ytService.downloadStreamForUpload(
          rawUrl,
          onProgress: (p, s) {
            if (mounted) setState(() => _statusMessage = s);
          },
        );
      } else {
        uploadFile = _selectedLocalFile!;
        sourceTitle = uploadFile.path.split(Platform.pathSeparator).last;
      }

      // 2. Upload to VPS Backend
      setState(() => _statusMessage = 'Uploading video to VPS backend...');
      final vpsVideoPath = await _apiService.uploadVideo(
        uploadFile,
        onProgress: (p, s) {
          if (mounted) setState(() => _statusMessage = s);
        },
      );

      // 3. Create Clipping Task
      setState(() => _statusMessage = 'Starting Gemini AI & FFmpeg clipping on VPS...');
      final taskId = await _apiService.createTask(
        videoPath: vpsVideoPath,
        title: sourceTitle,
        outputFormat: _outputFormat,
        clipLength: _clipLength,
        addSubtitles: _addSubtitles,
      );

      if (mounted) {
        setState(() => _isStartingTask = false);
        // Navigate to real-time progress screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskProgressScreen(
              taskId: taskId,
              videoTitle: sourceTitle,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingTask = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151530),
            title: const Text('Clipping Error', style: TextStyle(color: HaxTheme.neonRose)),
            content: Text('$e', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK', style: TextStyle(color: HaxTheme.neonCyan)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HaxLogo(size: 28),
            SizedBox(width: 10),
            Text('HAXCLIP'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings & Auth',
            icon: const Icon(Icons.tune_rounded, color: HaxTheme.neonCyan),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Clip History',
            icon: const Icon(Icons.history_rounded, color: HaxTheme.neonCyan),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClipsGalleryScreen(taskId: null),
                ),
              );
            },
          ),
        ],
      ),
      body: Hax3dBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // 3D Animated Title
                const Hax3dText(
                  text: 'AI 3D CLiPPER',
                  fontSize: 32,
                  letterSpacing: 2.5,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Transform Long Videos Into Viral Shorts In Seconds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HaxTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                // Server status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x3310B981),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HaxTheme.neonGreen.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, color: HaxTheme.neonGreen, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'VPS & FFmpeg Active • 100% Free YouTube',
                        style: TextStyle(
                          color: HaxTheme.neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mode Selector Toggle (YouTube vs Upload)
                _buildModeSelector(),

                const SizedBox(height: 20),

                // Main Input Card (3D Tilt Card)
                Hax3dTiltCard(
                  glowColor: _isYouTubeMode ? HaxTheme.neonCyan : HaxTheme.neonViolet,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isYouTubeMode) ...[
                        const Row(
                          children: [
                            Icon(Icons.play_circle_fill, color: Color(0xFFFF0033), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Direct YouTube Video Link',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'https://youtube.com/watch?v=...',
                            suffixIcon: _isFetchingDetails
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward, color: HaxTheme.neonCyan),
                                    onPressed: () => _fetchYouTubeMetadata(_urlController.text),
                                  ),
                          ),
                          onSubmitted: _fetchYouTubeMetadata,
                        ),

                        if (_ytInfo != null) ...[
                          const SizedBox(height: 14),
                          _buildYouTubePreview(_ytInfo!),
                        ],
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.video_file, color: HaxTheme.neonViolet, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Upload Video from Device',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Hax3dButton(
                          text: _selectedLocalFile == null
                              ? 'Browse Video File'
                              : 'Change: ${_selectedLocalFile!.path.split(Platform.pathSeparator).last}',
                          icon: Icons.folder_open_rounded,
                          primaryColor: HaxTheme.neonViolet,
                          textColor: Colors.white,
                          height: 50,
                          onPressed: _pickLocalFile,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Output Options Card
                Hax3dTiltCard(
                  glowColor: HaxTheme.neonPurple,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FORMAT & STYLING',
                        style: TextStyle(
                          color: HaxTheme.neonCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Format selector (9:16, 1:1, 16:9)
                      Row(
                        children: [
                          _buildFormatOption('9:16', 'TikTok / Reel', Icons.stay_current_portrait),
                          const SizedBox(width: 8),
                          _buildFormatOption('1:1', 'Square', Icons.crop_square),
                          const SizedBox(width: 8),
                          _buildFormatOption('16:9', 'Landscape', Icons.tv),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Clip Length & Subtitle Row
                      Row(
                        children: [
                          // Length dropdown
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F23),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x3300F0FF)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _clipLength,
                                  dropdownColor: const Color(0xFF151530),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'auto', child: Text('Auto Duration (<60s)')),
                                    DropdownMenuItem(value: 'short', child: Text('Short (<30s)')),
                                    DropdownMenuItem(value: 'medium', child: Text('Medium (30-60s)')),
                                    DropdownMenuItem(value: 'long', child: Text('Long (60-90s)')),
                                  ],
                                  onChanged: (v) => setState(() => _clipLength = v ?? 'auto'),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Subtitle toggle
                          GestureDetector(
                            onTap: () => setState(() => _addSubtitles = !_addSubtitles),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _addSubtitles ? HaxTheme.neonCyan.withOpacity(0.15) : const Color(0xFF0F0F23),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _addSubtitles ? HaxTheme.neonCyan : const Color(0x3300F0FF),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _addSubtitles ? Icons.subtitles : Icons.subtitles_off,
                                    color: _addSubtitles ? HaxTheme.neonCyan : HaxTheme.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Subtitles',
                                    style: TextStyle(
                                      color: _addSubtitles ? Colors.white : HaxTheme.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Status ticker when loading
                if (_isStartingTask) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xCC151530),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HaxTheme.neonCyan.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: HaxTheme.neonCyan),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: HaxTheme.neonCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Big Action 3D Button
                Hax3dButton(
                  text: _isStartingTask ? 'PROCESSING...' : 'GENERATE VIRAL CLIPS',
                  icon: Icons.auto_awesome,
                  isLoading: _isStartingTask,
                  primaryColor: HaxTheme.neonCyan,
                  height: 60,
                  onPressed: _isStartingTask ? null : _handleStartClipping,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF101026),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYouTubeMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _isYouTubeMode
                      ? const LinearGradient(colors: [HaxTheme.neonCyan, Color(0xFF00B4D8)])
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_display_rounded,
                        color: _isYouTubeMode ? Colors.black : Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'YouTube Link',
                        style: TextStyle(
                          color: _isYouTubeMode ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYouTubeMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: !_isYouTubeMode
                      ? const LinearGradient(colors: [HaxTheme.neonViolet, Color(0xFF7C3AED)])
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                        color: !_isYouTubeMode ? Colors.white : Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upload File',
                        style: TextStyle(
                          color: !_isYouTubeMode ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String format, String label, IconData icon) {
    final isSelected = _outputFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _outputFormat = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? HaxTheme.neonCyan.withOpacity(0.18) : const Color(0xFF0F0F23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? HaxTheme.neonCyan : const Color(0x3300F0FF),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? HaxTheme.neonCyan : HaxTheme.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                format,
                style: TextStyle(
                  color: isSelected ? Colors.white : HaxTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubePreview(YouTubeInfoModel info) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x80080815),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x3300F0FF)),
      ),
      child: Row(
        children: [
          // Thumbnail with duration
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Image.network(
                  info.thumbnailUrl,
                  width: 90,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 60,
                    color: Colors.black26,
                    child: const Icon(Icons.movie, color: Colors.white54),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.black87,
                    child: Text(
                      info.formattedDuration,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.author,
                  style: const TextStyle(color: HaxTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
