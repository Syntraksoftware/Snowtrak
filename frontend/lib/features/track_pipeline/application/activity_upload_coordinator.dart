import 'package:dio/dio.dart';
import 'package:syntrak/services/apis/activity_upload_api.dart';

/// Client-side orchestrator for Strava-style presigned upload (Phase 3).
///
/// 1. Request upload URL + placeholder activity row
/// 2. PUT raw file directly to Supabase Storage
/// 3. Notify activity-backend to enqueue / run pipeline
class ActivityUploadCoordinator {
  ActivityUploadCoordinator({
    required ActivityUploadApi uploadApi,
    Dio? rawUploadClient,
  })  : _uploadApi = uploadApi,
        _rawUploadClient = rawUploadClient ?? Dio();

  final ActivityUploadApi _uploadApi;
  final Dio _rawUploadClient;

  Future<UploadPipelineResult> uploadGpxFile({
    required List<int> fileBytes,
    String? name,
    String activityType = 'alpine',
  }) async {
    final reservation = await _uploadApi.requestUploadUrl(
      sourceType: 'gpx',
      name: name,
      activityType: activityType,
    );

    final activityId = reservation['activity_id'] as String;
    final uploadUrl = reservation['upload_url'] as String;
    final token = reservation['token'] as String?;

    await _rawUploadClient.put<List<int>>(
      uploadUrl,
      data: fileBytes,
      options: Options(
        headers: {
          'Content-Type': 'application/gpx+xml',
          if (token != null && token.isNotEmpty) 'x-upsert': 'true',
        },
        responseType: ResponseType.bytes,
      ),
    );

    final completion = await _uploadApi.completeUpload(activityId);
    return UploadPipelineResult(
      activityId: activityId,
      processingStatus: completion['processing_status'] as String? ?? 'processing',
      message: completion['message'] as String? ?? 'Pipeline started',
    );
  }
}

class UploadPipelineResult {
  const UploadPipelineResult({
    required this.activityId,
    required this.processingStatus,
    required this.message,
  });

  final String activityId;
  final String processingStatus;
  final String message;

  bool get isReady => processingStatus == 'ready';
}
