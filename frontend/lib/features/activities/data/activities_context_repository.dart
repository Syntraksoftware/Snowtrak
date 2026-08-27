import 'package:snowtrak/models/weather.dart';
import 'package:snowtrak/services/location_service.dart';
import 'package:snowtrak/services/weather_cache.dart';
import 'package:snowtrak/services/weather_service.dart';

class ActivitiesContextRepository {
  final WeatherService _weatherService;
  final LocationService _locationService;
  final WeatherCache _weatherCache;

  ActivitiesContextRepository({
    required WeatherService weatherService,
    required LocationService locationService,
    required WeatherCache weatherCache,
  })  : _weatherService = weatherService,
        _locationService = locationService,
        _weatherCache = weatherCache;

  Future<WeatherData?> readCachedWeather() async {
    final cached = await _weatherCache.read();
    return cached?.weather;
  }

  Future<WeatherData?> getLocalWeather({bool forceRefresh = false}) async {
    if (!await _locationService.hasLocationAccess()) {
      return readCachedWeather();
    }

    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      return readCachedWeather();
    }

    final cached = await _weatherCache.read();
    if (!forceRefresh &&
        cached != null &&
        cached.isFreshFor(
          latitude: position.latitude,
          longitude: position.longitude,
          maxAge: WeatherCache.cacheTtl,
        )) {
      return cached.weather;
    }

    final weather = await _weatherService.getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (weather != null) {
      await _weatherCache.write(
        latitude: position.latitude,
        longitude: position.longitude,
        weather: weather,
      );
      return weather;
    }

    return cached?.weather;
  }
}
