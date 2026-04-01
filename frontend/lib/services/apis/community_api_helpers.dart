class CommunityApiHelpers {
  CommunityApiHelpers._();

  static List<Map<String, dynamic>> parseListItems(dynamic data, String legacyKey) {
    if (data == null) {
      return [];
    }
    if (data is List) {
      return [for (final item in data) Map<String, dynamic>.from(item as Map)];
    }
    if (data is Map) {
      final typed = Map<String, dynamic>.from(data);
      if (typed['items'] is List) {
        final list = typed['items'] as List;
        return [for (final item in list) Map<String, dynamic>.from(item as Map)];
      }
      if (typed[legacyKey] is List) {
        final list = typed[legacyKey] as List;
        return [for (final item in list) Map<String, dynamic>.from(item as Map)];
      }
      if (typed.isEmpty) {
        return [];
      }
      throw FormatException(
        'List response missing expected "items" or "$legacyKey" key',
      );
    }
    throw const FormatException('List response was not a map or list');
  }

  static String mimeTypeForUploadFilename(String filename) {
    final lower = filename.toLowerCase();
    final dot = lower.lastIndexOf('.');
    if (dot < 0 || dot >= lower.length - 1) {
      return 'application/octet-stream';
    }
    switch (lower.substring(dot + 1)) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
