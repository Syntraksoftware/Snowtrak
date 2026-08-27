import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/screens/community/community_post_mapper.dart';
import 'package:snowtrak/services/feed/post_cache_codec.dart';

Map<String, dynamic> _raw({String? visibility}) => {
      'post_id': 'p1',
      'user_id': 'u1',
      'subthread_id': 's1',
      'title': 'Bluebird',
      'content': 'Perfect visibility all day',
      'created_at': '2026-01-01T00:00:00Z',
      if (visibility != null) 'visibility': visibility,
    };

void main() {
  test('a payload without the field reads as public', () {
    // The backend defaults the column, but a cached payload written before
    // this shipped has no field at all. It must not read as private.
    expect(CommunityPostMapper.mapBackendPost(_raw(), const []).visibility, 'public');
    expect(CommunityPostMapper.mapBackendPost(_raw(visibility: ''), const []).visibility, 'public');
  });

  test('the tier survives the mapper', () {
    final post = CommunityPostMapper.mapBackendPost(_raw(visibility: 'followers'), const []);
    expect(post.visibility, 'followers');
    expect(post.isPublic, isFalse);
  });

  test('the tier survives the on-device cache', () {
    final post = CommunityPostMapper.mapBackendPost(_raw(visibility: 'private'), const []);
    final restored = PostCacheCodec.fromJson(PostCacheCodec.toJson(post));
    expect(restored.visibility, 'private');
  });

  test('a cache entry written before the field decodes as public', () {
    final json = PostCacheCodec.toJson(
      Post(
        id: 'p1',
        author: PostAuthor(id: 'u1', displayName: 'U', username: 'u'),
        text: 'x',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        timestampLabel: '1h',
      ),
    )..remove('visibility');
    expect(PostCacheCodec.fromJson(json).visibility, 'public');
  });
}
