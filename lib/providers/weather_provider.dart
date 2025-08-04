import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/models/city_model.dart';
import 'package:weather_app/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  Weather? weather;
  List<Weather>? forecast;
  List<Weather>? dailyForecast;
  String cityName = "Almaty";
  String? errorMessage;

  Future<void> fetchWeatherAndForecast(String city) async {
    weather = null;
    forecast = null;
    dailyForecast = null;
    errorMessage = null;
    notifyListeners();
    try {
      final current = await _weatherService.getWeather(city);
      final forecastData = await _weatherService.getForecast(city);
      final daily = _processDailyForecast(forecastData);
      weather = current;
      forecast = forecastData;
      dailyForecast = daily;
      cityName = current.cityName;
      errorMessage = null;
    } catch (e) {
      weather = null;
      forecast = null;
      dailyForecast = null;
      if (e.toString().contains('404')) {
        errorMessage = 'Город не найден. Пожалуйста, проверьте название.';
      } else {
        errorMessage = 'Не удалось загрузить данные о погоде. Проверьте подключение к Интернету.';
      }
    }
    notifyListeners();
  }

  Future<void> fetchWeatherAndForecastByCoordinates(double lat, double lon) async {
    weather = null;
    forecast = null;
    dailyForecast = null;
    errorMessage = null;
    notifyListeners();
    try {
      final current = await _weatherService.getWeatherByCoordinates(lat, lon);
      final forecastData = await _weatherService.getForecastByCoordinates(lat, lon);
      final daily = _processDailyForecast(forecastData);
      final city = await _weatherService.reverseGeocode(lat, lon);
      weather = Weather(
        cityName: city,
        temperature: current.temperature,
        mainCondition: current.mainCondition,
        iconCode: current.iconCode,
        weatherId: current.weatherId,
        dateTime: current.dateTime,
        minTemperature: current.minTemperature,
        maxTemperature: current.maxTemperature,
      );
      forecast = forecastData;
      dailyForecast = daily;
      cityName = city;
      errorMessage = null;
    } catch (e) {
      weather = null;
      forecast = null;
      dailyForecast = null;
      errorMessage = 'Не удалось загрузить данные о погоде по местоположению.';
    }
    notifyListeners();
  }

  Future<List<City>> searchCities(String pattern) async {
    return await _weatherService.searchCities(pattern);
  }

  List<Weather> _processDailyForecast(List<Weather> hourlyForecast) {
    if (hourlyForecast.isEmpty) return [];
    final Map<String, List<Weather>> dailyGroupedForecast = {};
    for (var item in hourlyForecast) {
      final dateKey = item.dateTime!.toIso8601String().substring(0, 10);
      if (!dailyGroupedForecast.containsKey(dateKey)) {
        dailyGroupedForecast[dateKey] = [];
      }
      dailyGroupedForecast[dateKey]!.add(item);
    }
    final List<Weather> processedDailyForecast = [];
    final now = DateTime.now();
    final todayKey = now.toIso8601String().substring(0, 10);
    dailyGroupedForecast.forEach((dateKey, dayItems) {
      if (dateKey == todayKey) return;
      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      Weather? mainDayWeather;
      dayItems.sort((a, b) => a.dateTime!.compareTo(b.dateTime!));
      for (var item in dayItems) {
        minTemp = minTemp < item.temperature ? minTemp : item.temperature;
        maxTemp = maxTemp > item.temperature ? maxTemp : item.temperature;
        if (mainDayWeather == null ||
            (item.dateTime!.hour - 12).abs() < (mainDayWeather.dateTime!.hour - 12).abs()) {
          mainDayWeather = item;
        }
      }
      if (mainDayWeather != null) {
        processedDailyForecast.add(
          Weather(
            cityName: mainDayWeather.cityName,
            temperature: mainDayWeather.temperature,
            mainCondition: mainDayWeather.mainCondition,
            iconCode: mainDayWeather.iconCode,
            weatherId: mainDayWeather.weatherId,
            dateTime: mainDayWeather.dateTime,
            minTemperature: minTemp,
            maxTemperature: maxTemp,
          ),
        );
      }
    });
    processedDailyForecast.sort((a, b) => a.dateTime!.compareTo(b.dateTime!));
    return processedDailyForecast.take(4).toList();
  }
}
