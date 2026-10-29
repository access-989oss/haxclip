class YouTubeInfoModel {
  final String id;
  final String title;
  final String author;
  final Duration? duration;
  final String thumbnailUrl;
  final String originalUrl;

  YouTubeInfoModel({
    required this.id,
    required this.title,
    required this.author,
    this.duration,
    required this.thumbnailUrl,
    required this.originalUrl,
  });

  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
