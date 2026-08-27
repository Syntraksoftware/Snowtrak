import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowtrak/models/weather.dart';

class CachedWeatherEntry {
  const CachedWeatherEntry({
    required this.latitude,
    required this.longitude,
    required this.cachedAt,
    required this.weather,
  });

  final double latitude;
  final double longitude;
  final DateTime cachedAt;
  final WeatherData weather;

  bool isFreshFor({
    required double latitude,
    required double longitude,
    required Duration maxAge,
  }) {
    if (DateTime.now().difference(cachedAt) > maxAge) {
      return false;
    }

    return WeatherCache.locationKey(latitude, longitude) ==
        WeatherCache.locationKey(this.latitude, this.longitude);
  }
}

class WeatherCache {
  static const _storageKey = 'weather_cache_v1';
  static const cacheTtl = Duration(minutes: 45);

  static String locationKey(double latitude, double longitude) {
    final roundedLat = (latitude * 100).round() / 100;
    final roundedLng = (longitude * 100).round() / 100;
    return '${roundedLat.toStringAsFixed(2)}:${roundedLng.toStringAsFixed(2)}';
  }

  Future<CachedWeatherEntry?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CachedWeatherEntry(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        weather: WeatherData.fromCacheJson(
          json['weather'] as Map<String, dynamic>,
        ),
      );
    } catch (_) {
      await prefs.remove(_storageKey);
      return null;
    }
  }

  Future<void> write({
    required double latitude,
    required double longitude,
    required WeatherData weather,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'cachedAt': DateTime.now().toIso8601String(),
      'weather': weather.toCacheJson(),
    });
    await prefs.setString(_storageKey, payload);
  }
}
