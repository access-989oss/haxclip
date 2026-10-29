import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../models/task_model.dart';

class ApiService {
  String get _baseUrl => AppConfig.backendUrl.replaceAll(RegExp(r'/+$'), '');
  String get _apiKey => AppConfig.apiKey;

  Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'Accept': 'application/json',
      };

  /// Upload a video file (from YouTube download or local storage) to the VPS backend
  Future<String> uploadVideo(
    File file, {
    Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Connecting to VPS server...');
    final uri = Uri.parse('$_baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);

    final fileSize = await file.length();
    final stream = http.ByteStream(file.openRead());
    final multipartFile = http.MultipartFile(
      'video',
      stream,
      fileSize,
      filename: file.path.split(Platform.pathSeparator).last,
    );
    request.files.add(multipartFile);

    onProgress?.call(0.3, 'Transferring video to VPS backend...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final videoPath = data['video_path'] ?? data['url'] ?? data['path'];
      if (videoPath != null) {
        onProgress?.call(1.0, 'Video uploaded to VPS successfully');
        return videoPath.toString();
      }
      throw Exception('Upload completed but missing video path in response: ${response.body}');
    } else {
      throw Exception('VPS Upload failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Create an AI clipping task on the VPS backend
  Future<String> createTask({
    required String videoPath,
    String? title,
    String outputFormat = '9:16',
    String clipLength = 'auto',
    bool addSubtitles = true,
    String captionTemplate = 'default',
  }) async {
    final uri = Uri.parse('$_baseUrl/tasks/');
    final body = jsonEncode({
      'source': {
        'type': 'upload',
        'url': videoPath,
        'title': title ?? 'HaxClip Mobile Video',
      },
      'output_format': outputFormat,
      'clip_length': clipLength,
      'add_subtitles': addSubtitles,
      'caption_template': captionTemplate,
      'processing_mode': 'fast',
    });

    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final taskId = data['task_id'] ?? data['id'];
      if (taskId != null) {
        return taskId.toString();
      }
      throw Exception('Task created but no task_id returned: ${response.body}');
    } else {
      throw Exception('Failed to create task on VPS (${response.statusCode}): ${response.body}');
    }
  }

  /// Get status of a task
  Future<TaskModel> getTask(String taskId) async {
    final uri = Uri.parse('$_baseUrl/tasks/$taskId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return TaskModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch task $taskId (${response.statusCode}): ${response.body}');
    }
  }

  /// List user's tasks
  Future<List<TaskModel>> listTasks() async {
    final uri = Uri.parse('$_baseUrl/tasks/');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawTasks = data['tasks'] as List? ?? [];
      return rawTasks.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to list tasks (${response.statusCode}): ${response.body}');
    }
  }

  /// Download clip video file to local device storage
  Future<File> downloadClipVideo(
    String taskId,
    String clipId, {
    Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse('$_baseUrl/tasks/$taskId/clips/$clipId/file');
    final client = http.Client();
    final request = http.Request('GET', uri);
    request.headers.addAll(_headers);

    final response = await client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to download clip (${response.statusCode})');
    }

    final totalBytes = response.contentLength ?? 0;
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/clip_${taskId}_$clipId.mp4');
    final sink = file.openWrite();

    int receivedBytes = 0;
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress?.call(receivedBytes / totalBytes);
      }
    }

    await sink.flush();
    await sink.close();
    client.close();
    return file;
  }

  /// Fetch authenticated user profile from VPS
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final uri = Uri.parse('$_baseUrl/account/me');
    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch profile (${response.statusCode}): ${response.body}');
    }
  }

  /// Check if the VPS backend is reachable
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

