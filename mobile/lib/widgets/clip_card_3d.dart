import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../theme/hax_theme.dart';
import 'hax_3d_button.dart';
import 'hax_3d_tilt_card.dart';

class ClipCard3d extends StatefulWidget {
  final ClipModel clip;
  final String taskId;

  const ClipCard3d({
    super.key,
    required this.clip,
    required this.taskId,
  });

  @override
  State<ClipCard3d> createState() => _ClipCard3dState();
}

class _ClipCard3dState extends State<ClipCard3d> {
  final ApiService _apiService = ApiService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;

  Color get _scoreColor {
    final s = widget.clip.viralityScore;
    if (s >= 85) return HaxTheme.neonGreen;
    if (s >= 70) return HaxTheme.neonCyan;
    return HaxTheme.neonAmber;
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final file = await _apiService.downloadClipVideo(
        widget.taskId,
        widget.clip.id,
        onProgress: (p) => setState(() => _downloadProgress = p),
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadedFilePath = file.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF151530),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: HaxTheme.neonGreen, width: 1.5),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: HaxTheme.neonGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saved clip: ${file.path.split('/').last}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A1015),
          content: Text('Download failed: $e', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _handleShare() async {
    try {
      String filePath;
      if (_downloadedFilePath != null) {
        filePath = _downloadedFilePath!;
      } else {
        final file = await _apiService.downloadClipVideo(widget.taskId, widget.clip.id);
        filePath = file.path;
        if (mounted) setState(() => _downloadedFilePath = filePath);
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out this viral clip: ${widget.clip.hookTitle} 🔥 #HaxClip',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share error: $e')),
      );
    }
  }

  Future<void> _handleWatch() async {
    final directUrl = Uri.parse(
      '${AppConfig.backendUrl}/tasks/${widget.taskId}/clips/${widget.clip.id}/file',
    );
    if (await canLaunchUrl(directUrl)) {
      await launchUrl(directUrl, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTime(double sec) {
    final m = (sec / 60).floor();
    final s = (sec % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Hax3dTiltCard(
      glowColor: _scoreColor,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Hook Badge + Virality Dial
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hook type pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HaxTheme.neonViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HaxTheme.neonViolet.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, color: HaxTheme.neonViolet, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.clip.hookType.toUpperCase(),
                      style: const TextStyle(
                        color: HaxTheme.neonViolet,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Virality Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _scoreColor.withOpacity(0.25),
                      _scoreColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _scoreColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _scoreColor.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: _scoreColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.clip.viralityScore}% VIRAL',
                      style: TextStyle(
                        color: _scoreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            widget.clip.hookTitle.isNotEmpty ? widget.clip.hookTitle : 'Clip ${widget.clip.filename}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 8),

          // Time Range & Duration
          Row(
            children: [
              Icon(Icons.timer_outlined, color: HaxTheme.neonCyan.withOpacity(0.8), size: 15),
              const SizedBox(width: 5),
              Text(
                '${_formatTime(widget.clip.startTime)} - ${_formatTime(widget.clip.endTime)}',
                style: const TextStyle(
                  color: HaxTheme.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(
                '${widget.clip.duration.toStringAsFixed(0)}s length',
                style: const TextStyle(color: HaxTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Subtitle Transcript Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x66080815),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Text(
              widget.clip.text.isNotEmpty ? '"${widget.clip.text}"' : 'Transcription processing...',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Score breakdown pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniScore('Hook', widget.clip.hookScore),
              _buildMiniScore('Engage', widget.clip.engagementScore),
              _buildMiniScore('Value', widget.clip.valueScore),
              _buildMiniScore('Share', widget.clip.shareabilityScore),
            ],
          ),

          const SizedBox(height: 18),

          // Action Buttons: Watch, Download, Share
          Row(
            children: [
              // Watch Preview
              Expanded(
                flex: 1,
                child: Hax3dButton(
                  text: 'Watch',
                  icon: Icons.play_arrow_rounded,
                  primaryColor: const Color(0xFF1E293B),
                  textColor: HaxTheme.neonCyan,
                  height: 44,
                  onPressed: _handleWatch,
                ),
              ),
              const SizedBox(width: 8),

              // Download
              Expanded(
                flex: 2,
                child: Hax3dButton(
                  text: _isDownloading
                      ? '${(_downloadProgress * 100).toInt()}%'
                      : 'Download',
                  icon: _isDownloading ? null : Icons.download_rounded,
                  isLoading: _isDownloading,
                  primaryColor: HaxTheme.neonCyan,
                  height: 44,
                  onPressed: _handleDownload,
                ),
              ),
              const SizedBox(width: 8),

              // Share
              Expanded(
                flex: 1,
                child: Hax3dButton(
                  text: 'Share',
                  icon: Icons.share_rounded,
                  primaryColor: HaxTheme.neonViolet,
                  textColor: Colors.white,
                  height: 44,
                  onPressed: _handleShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: HaxTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
