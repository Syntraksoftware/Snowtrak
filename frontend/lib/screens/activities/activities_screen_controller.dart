import 'dart:async';
import 'package:snowtrak/features/activities/data/activities_context_repository.dart';
import 'package:snowtrak/models/weather.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';

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
    unawaited(authProvider.refreshUserData());
    await _loadWeatherStaleWhileRevalidate(
      contextRepository: contextRepository,
      onWeatherLoaded: onWeatherLoaded,
      forceRefresh: false,
    );
  }

  Future<void> refreshData({
    required ActivityProvider activityProvider,
    required ActivitiesContextRepository contextRepository,
    required Future<void> Function(WeatherData? weather) onWeatherLoaded,
  }) async {
    await activityProvider.loadActivities(refresh: true, forceNetwork: true);
    await _loadWeatherStaleWhileRevalidate(
      contextRepository: contextRepository,
      onWeatherLoaded: onWeatherLoaded,
      forceRefresh: true,
    );
  }

  Future<void> _loadWeatherStaleWhileRevalidate({
    required ActivitiesContextRepository contextRepository,
    required Future<void> Function(WeatherData? weather) onWeatherLoaded,
    required bool forceRefresh,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await contextRepository.readCachedWeather();
        if (cached != null) {
          await onWeatherLoaded(cached);
        }
      }

      final weather = await contextRepository.getLocalWeather(
        forceRefresh: forceRefresh,
      );
      await onWeatherLoaded(weather);
    } catch (_) {
      if (forceRefresh) {
        await onWeatherLoaded(null);
      }
    }
  }
}
