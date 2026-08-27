import 'package:dio/dio.dart';

/// Presigned upload flow for async GPX/FIT pipeline (Phase 3).
class ActivityUploadApi {
  ActivityUploadApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> requestUploadUrl({
    required String sourceType,
    String? name,
    String activityType = 'alpine',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/activities/upload-url',
      data: {
        'source_type': sourceType,
        if (name != null) 'name': name,
        'activity_type': activityType,
      },
    );
    return Map<String, dynamic>.from(response.data ?? const {});
  }

  Future<Map<String, dynamic>> completeUpload(String activityId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/activities/$activityId/upload-complete',
    );
    return Map<String, dynamic>.from(response.data ?? const {});
  }
}
