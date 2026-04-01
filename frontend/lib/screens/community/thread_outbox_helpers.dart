List<String>? parseOutboxMediaUrls(Map<String, dynamic> payload) {
  final raw = payload['media_urls'];
  if (raw is! List || raw.isEmpty) {
    return null;
  }
  final out = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  return out.isEmpty ? null : out;
}
