import 'package:image_picker/image_picker.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/services/community_service.dart';

/// Uploads local picks sequentially; stops on first failure.
Future<AppResult<List<String>>> uploadThreadMediaFiles(
  CommunityService service,
  List<XFile> files,
) async {
  final urls = <String>[];
  for (final f in files) {
    final r = await service.uploadMedia(f);
    switch (r) {
      case AppSuccess(:final value):
        urls.add(value);
      case AppFailure(:final error):
        return AppFailure(error);
    }
  }
  return AppSuccess(urls);
}
