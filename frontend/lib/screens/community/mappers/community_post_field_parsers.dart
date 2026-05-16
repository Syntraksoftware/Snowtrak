class CommunityPostFieldParsers {
  CommunityPostFieldParsers._();

  static List<String>? parseMediaUrls(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is List) {
      final out = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      return out.isEmpty ? null : out;
    }
    return null;
  }

  static String? topicFromStructuredTitle(String? title) {
    final t = (title ?? '').trim();
    const sep = ' > ';
    final i = t.indexOf(sep);
    if (i <= 0) {
      return null;
    }
    final topic = t.substring(0, i).trim();
    return topic.isEmpty ? null : topic;
  }

  static String timestampLabel(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
