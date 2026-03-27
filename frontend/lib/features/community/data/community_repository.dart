import 'package:syntrak/services/apis/community_api.dart';

class CommunityRepository {
  CommunityRepository(this._api);

  final CommunityApi _api;

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _api.getPostsByUserId(userId, limit: limit, offset: offset);
  }
}
