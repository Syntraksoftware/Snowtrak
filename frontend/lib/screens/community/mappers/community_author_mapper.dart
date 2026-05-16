class CommunityAuthorMapper {
  CommunityAuthorMapper._();

  static bool looksLikeUuid(String s) {
    final t = s.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(t);
  }

  static String usernameFromEmailOrId(String? email, String? fallbackId) {
    final e = (email ?? '').trim();
    if (e.contains('@')) {
      return e.split('@').first;
    }
    final id = (fallbackId ?? '').trim();
    if (id.isEmpty) {
      return 'user';
    }
    if (looksLikeUuid(id)) {
      return 'member';
    }
    return id.length > 12 ? id.substring(0, 12) : id;
  }

  static String authorDisplayName({
    String? firstName,
    String? lastName,
    required String fallback,
  }) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first $last'.trim();
    }
    final fb = fallback.trim();
    if (looksLikeUuid(fb)) {
      return 'Member';
    }
    if (fb.contains('@')) {
      return fb.split('@').first;
    }
    return usernameFromEmailOrId(null, fb);
  }
}
