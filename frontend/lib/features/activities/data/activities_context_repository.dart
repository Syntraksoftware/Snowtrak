import 'package:syntrak/models/weather.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/weather_service.dart';

class ActivitiesContextRepository {
  final WeatherService _weatherService;
  final LocationService _locationService;

  ActivitiesContextRepository({
    required WeatherService weatherService,
    required LocationService locationService,
  })  : _weatherService = weatherService,
        _locationService = locationService;

  Future<WeatherData?> getLocalWeather() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      return null;
    }

    return _weatherService.getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
