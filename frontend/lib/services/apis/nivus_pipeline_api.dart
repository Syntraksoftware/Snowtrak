import 'package:dio/dio.dart';

/// Thin HTTP client for the Nivus compute microservice.
///
/// Contract mirrors `backend/shared/track_pipeline_schemas.py` and
/// `nivus/models.py` — snake_case JSON, no domain logic here.
class NivusPipelineApi {
  NivusPipelineApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const processPath = '/api/v1/pipeline/process';

  Future<Map<String, dynamic>> processPipeline(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(processPath, data: body);
    return Map<String, dynamic>.from(response.data ?? const {});
  }
}
