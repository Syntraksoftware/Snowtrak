import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/screens/community/mappers/community_author_mapper.dart';

void main() {
  // The same four cases the Python half is tested against. Two
  // implementations of one rule is the cost of the community feed sending
  // raw fields; testing them identically is what keeps them honest.
  test('a chosen username wins and carries the at sign', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: 'snowking',
        firstName: 'Matthew',
        lastName: 'Ng',
        fallback: 'matthew@example.com',
      ),
      '@snowking',
    );
  });

  test('without a username the name shows with no at sign', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: null,
        firstName: 'Matthew',
        lastName: 'Ng',
        fallback: 'matthew@example.com',
      ),
      'Matthew Ng',
    );
  });

  test('with neither it falls back to the email handle', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: null,
        firstName: null,
        lastName: null,
        fallback: 'skier@example.com',
      ),
      'skier',
    );
  });

  test('a blank username counts as absent', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: '   ',
        firstName: 'Matthew',
        lastName: 'Ng',
        fallback: 'matthew@example.com',
      ),
      'Matthew Ng',
    );
  });

  test('a fallback with no @ to split on reads as gone entirely', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: null,
        firstName: null,
        lastName: null,
        fallback: 'unknown',
      ),
      'Skier',
    );
  });

  test('an empty fallback also reads as gone entirely', () {
    expect(
      CommunityAuthorMapper.authorDisplayName(
        username: '',
        firstName: '  ',
        lastName: null,
        fallback: '',
      ),
      'Skier',
    );
  });
}
