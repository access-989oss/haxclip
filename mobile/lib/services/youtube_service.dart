import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/youtube_info_model.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Extract video metadata without downloading
  Future<YouTubeInfoModel?> getVideoDetails(String rawUrl) async {
    try {
      final videoId = VideoId(rawUrl);
      final video = await _yt.videos.get(videoId);

      return YouTubeInfoModel(
        id: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.highResUrl,
        originalUrl: rawUrl,
      );
    } catch (e) {
      // Try resolving directly if user pasted a short link or search
      try {
        final video = await _yt.videos.get(rawUrl);
        return YouTubeInfoModel(
          id: video.id.value,
          title: video.title,
          author: video.author,
          duration: video.duration,
          thumbnailUrl: video.thumbnails.highResUrl,
          originalUrl: rawUrl,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Download YouTube video/audio stream directly on device (free, bypassing VPS datacenter IP block)
  Future<File> downloadStreamForUpload(
    String rawUrl, {
    Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.05, 'Extracting YouTube stream manifests...');
    final video = await _yt.videos.get(rawUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);

    // Prefer muxed (video+audio, e.g. 720p/360p mp4) for best compatibility
    StreamInfo? chosenStream;
    try {
      chosenStream = manifest.muxed.withHighestBitrate();
    } catch (_) {}

    chosenStream ??= manifest.audioOnly.withHighestBitrate();

    onProgress?.call(0.15, 'Downloading video directly on phone...');
    final stream = _yt.videos.streamsClient.get(chosenStream);

    final tempDir = await getTemporaryDirectory();
    final ext = chosenStream.container.name;
    final file = File('${tempDir.path}/yt_${video.id.value}.$ext');
    if (await file.exists()) {
      await file.delete();
    }

    final output = file.openWrite();
    final totalBytes = chosenStream.size.totalBytes;
    int receivedBytes = 0;

    await for (final chunk in stream) {
      output.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        final progress = 0.15 + (receivedBytes / totalBytes) * 0.70; // 15% -> 85%
        final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
        final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
        onProgress?.call(progress, 'Downloading stream ($mbReceived / $mbTotal MB)...');
      }
    }

    await output.flush();
    await output.close();

    onProgress?.call(0.90, 'Stream cached. Preparing for VPS AI processing...');
    return file;
  }

  void dispose() {
    _yt.close();
  }
}
