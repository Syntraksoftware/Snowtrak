class CommunityAuthorMapper {
  CommunityAuthorMapper._();

  /// The name to show for one author.
  ///
  /// Mirrors `backend/shared/display_name.py`'s `display_name` case for
  /// case: a chosen handle wins and carries the `@`, then the full name,
  /// then the fallback's email handle, then `fallback` itself when it
  /// carries no `@` to split on. The community feed has no `deleted` bit to
  /// check here -- a gone author never reaches this mapper with a row to
  /// map in the first place.
  static String authorDisplayName({
    String? username,
    String? firstName,
    String? lastName,
    required String fallback,
  }) {
    // The @ marks a handle, never a person, so it appears here and nowhere
    // further down the ladder.
    final handle = (username ?? '').trim();
    if (handle.isNotEmpty) {
      return '@$handle';
    }
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final full = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (full.isNotEmpty) {
      return full;
    }
    final fb = fallback.trim();
    if (fb.contains('@')) {
      return fb.split('@').first;
    }
    // Matches display_name.py's final rung exactly: a fallback with no `@`
    // to split on -- blank, or a raw id with nothing else to show -- reads
    // as "nothing to name this author by", same as the Python side's
    // deleted-author case.
    return 'Skier';
  }
}
