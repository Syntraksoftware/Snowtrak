import 'package:syntrak/models/weather.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/weather_service.dart';

class ActivitiesContextRepository {
  static const double _defaultLatitude = 52.52;
  static const double _defaultLongitude = 13.41;

  final WeatherService _weatherService;
  final LocationService _locationService;

  ActivitiesContextRepository({
    required WeatherService weatherService,
    required LocationService locationService,
  })  : _weatherService = weatherService,
        _locationService = locationService;

  Future<WeatherData?> getLocalWeather() async {
    final position = await _locationService.getCurrentPosition();
    final latitude = position?.latitude ?? _defaultLatitude;
    final longitude = position?.longitude ?? _defaultLongitude;

    return _weatherService.getWeather(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
