import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/models/weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch weather data for given coordinates
  /// 
  /// [latitude] - Latitude coordinate
  /// [longitude] - Longitude coordinate
  /// Returns WeatherData or null if request fails
  Future<WeatherData?> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m&timezone=auto',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather request timeout');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(jsonData);
      } else {
        AppLogger.instance.debug('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.instance.debug('Error fetching weather: $e');
      return null;
    }
  }
}

