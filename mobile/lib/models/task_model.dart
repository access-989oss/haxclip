class ClipModel {
  final String id;
  final String filename;
  final double startTime;
  final double endTime;
  final double duration;
  final String text;
  final int viralityScore;
  final int hookScore;
  final int engagementScore;
  final int valueScore;
  final int shareabilityScore;
  final String hookType;
  final String hookTitle;
  final String reasoning;
  final String? videoUrl;

  ClipModel({
    required this.id,
    required this.filename,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.text,
    required this.viralityScore,
    required this.hookScore,
    required this.engagementScore,
    required this.valueScore,
    required this.shareabilityScore,
    required this.hookType,
    required this.hookTitle,
    required this.reasoning,
    this.videoUrl,
  });

  factory ClipModel.fromJson(Map<String, dynamic> json) {
    return ClipModel(
      id: json['id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      startTime: (json['start_time'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['end_time'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      text: json['text']?.toString() ?? '',
      viralityScore: (json['virality_score'] as num?)?.toInt() ?? 85,
      hookScore: (json['hook_score'] as num?)?.toInt() ?? 80,
      engagementScore: (json['engagement_score'] as num?)?.toInt() ?? 82,
      valueScore: (json['value_score'] as num?)?.toInt() ?? 84,
      shareabilityScore: (json['shareability_score'] as num?)?.toInt() ?? 88,
      hookType: json['hook_type']?.toString() ?? 'High Energy',
      hookTitle: json['hook_title']?.toString() ?? 'Viral Moment',
      reasoning: json['reasoning']?.toString() ?? '',
      videoUrl: json['video_url']?.toString(),
    );
  }
}

class TaskModel {
  final String id;
  final String status;
  final String? sourceTitle;
  final String? sourceType;
  final int clipsCount;
  final List<ClipModel> clips;
  final String? errorMessage;
  final double progress;
  final String? currentStage;
  final DateTime? createdAt;

  TaskModel({
    required this.id,
    required this.status,
    this.sourceTitle,
    this.sourceType,
    this.clipsCount = 0,
    this.clips = const [],
    this.errorMessage,
    this.progress = 0.0,
    this.currentStage,
    this.createdAt,
  });

  bool get isProcessing => status == 'processing' || status == 'queued' || status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    var rawClips = json['clips'];
    List<ClipModel> parsedClips = [];
    if (rawClips is List) {
      parsedClips = rawClips
          .whereType<Map<String, dynamic>>()
          .map((c) => ClipModel.fromJson(c))
          .toList();
    }

    double progressVal = 0.0;
    if (json['progress'] != null) {
      progressVal = (json['progress'] as num).toDouble();
      if (progressVal > 1.0) progressVal = progressVal / 100.0;
    }

    return TaskModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      sourceTitle: json['source_title']?.toString() ?? json['title']?.toString(),
      sourceType: json['source_type']?.toString(),
      clipsCount: (json['clips_count'] as num?)?.toInt() ?? parsedClips.length,
      clips: parsedClips,
      errorMessage: json['error_message']?.toString() ?? json['error']?.toString(),
      progress: progressVal,
      currentStage: json['stage']?.toString() ?? json['message']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
