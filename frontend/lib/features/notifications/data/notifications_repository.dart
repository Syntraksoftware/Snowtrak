import 'package:syntrak/models/notification.dart';
import 'package:syntrak/services/apis/notifications_api.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final NotificationsApi _api;

  Future<List<AppNotification>> getPending() {
    return _api.getPending();
  }

  Future<List<AppNotification>> getHistory({int limit = 50}) {
    return _api.getHistory(limit: limit);
  }
}
