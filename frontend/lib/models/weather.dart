class WeatherData {
  final double temperature;
  final double windSpeed;
  final DateTime time;
  final List<HourlyWeather> hourly;

  WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.time,
    required this.hourly,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    
    final hourlyTimes = (hourly['time'] as List).cast<String>();
    final hourlyTemps = (hourly['temperature_2m'] as List).cast<double>();
    final hourlyHumidity = (hourly['relative_humidity_2m'] as List).cast<int>();
    final hourlyWind = (hourly['wind_speed_10m'] as List).cast<double>();

    final hourlyWeather = List<HourlyWeather>.generate(
      hourlyTimes.length,
      (index) => HourlyWeather(
        time: DateTime.parse(hourlyTimes[index]),
        temperature: hourlyTemps[index],
        humidity: hourlyHumidity[index],
        windSpeed: hourlyWind[index],
      ),
    );

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      time: DateTime.parse(current['time'] as String),
      hourly: hourlyWeather,
    );
  }

  // Get weather condition based on temperature and humidity
  WeatherCondition get condition {
    if (temperature < 0) {
      return WeatherCondition.snow;
    } else if (temperature < 10) {
      return WeatherCondition.cloudy;
    } else if (temperature < 20) {
      return WeatherCondition.partlyCloudy;
    } else {
      return WeatherCondition.sunny;
    }
  }

  // Get next 7 days forecast (simplified - using hourly data)
  List<DailyForecast> get weeklyForecast {
    final now = DateTime.now();
    final forecasts = <DailyForecast>[];
    
    // Group hourly data by day
    final dailyData = <DateTime, List<HourlyWeather>>{};
    for (var hourly in this.hourly) {
      final day = DateTime(hourly.time.year, hourly.time.month, hourly.time.day);
      dailyData.putIfAbsent(day, () => []).add(hourly);
    }

    // Get next 7 days
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final dayData = dailyData[day];
      if (dayData != null && dayData.isNotEmpty) {
        final avgTemp = dayData.map((h) => h.temperature).reduce((a, b) => a + b) / dayData.length;
        final maxTemp = dayData.map((h) => h.temperature).reduce((a, b) => a > b ? a : b);
        final minTemp = dayData.map((h) => h.temperature).reduce((a, b) => a < b ? a : b);
        
        forecasts.add(DailyForecast(
          date: day,
          maxTemp: maxTemp,
          minTemp: minTemp,
          avgTemp: avgTemp,
        ));
      }
    }

    return forecasts;
  }
}

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int humidity;
  final double windSpeed;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
  });
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double avgTemp;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.avgTemp,
  });
}

enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  snow,
}

extension WeatherConditionExtension on WeatherCondition {
  String get emoji {
    switch (this) {
      case WeatherCondition.sunny:
        return '☀️';
      case WeatherCondition.partlyCloudy:
        return '⛅';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rainy:
        return '🌧️';
      case WeatherCondition.snow:
        return '❄️';
    }
  }

  String get description {
    switch (this) {
      case WeatherCondition.sunny:
        return 'Sunny';
      case WeatherCondition.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.snow:
        return 'Snow';
    }
  }
}

