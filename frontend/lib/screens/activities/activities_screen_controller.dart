import 'package:syntrak/features/activities/data/activities_context_repository.dart';
import 'package:syntrak/models/weather.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/auth_provider.dart';

class ActivitiesScreenController {
  const ActivitiesScreenController();

  Future<void> loadInitialData({
    required ActivityProvider activityProvider,
    required AuthProvider authProvider,
    required ActivitiesContextRepository contextRepository,
    required Future<void> Function(WeatherData? weather) onWeatherLoaded,
  }) async {
    await activityProvider.loadActivities(refresh: true);
    if (activityProvider.activities.isEmpty && !activityProvider.isLoading) {
      activityProvider.loadMockActivities();
    }
    authProvider.refreshUserData();
    final weather = await _getLocalWeatherSafe(contextRepository);
    await onWeatherLoaded(weather);
  }

  Future<void> refreshData({
    required ActivityProvider activityProvider,
    required ActivitiesContextRepository contextRepository,
    required Future<void> Function(WeatherData? weather) onWeatherLoaded,
  }) async {
    await activityProvider.loadActivities(refresh: true);
    final weather = await _getLocalWeatherSafe(contextRepository);
    await onWeatherLoaded(weather);
  }

  Future<WeatherData?> _getLocalWeatherSafe(
    ActivitiesContextRepository contextRepository,
  ) async {
    try {
      return await contextRepository.getLocalWeather();
    } catch (_) {
      return null;
    }
  }
}
