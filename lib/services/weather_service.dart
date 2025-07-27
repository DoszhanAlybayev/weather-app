
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_model.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static const String BASE_URL = 'http://api.openweathermap.org/data/2.5';
  final String apiKey = dotenv.env['OPEN_WEATHER_API_KEY']!;
  WeatherService(); 

  // Метод для получения текущей погоды по названию города
  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(Uri.parse('$BASE_URL/weather?q=$cityName&appid=$apiKey&units=metric&lang=ru'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  // Метод для получения прогноза погоды (5 дней / каждые 3 часа)
  Future<List<Weather>> getForecast(String cityName) async {
    final response = await http.get(Uri.parse('$BASE_URL/forecast?q=$cityName&appid=$apiKey&units=metric&lang=ru'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> forecastList = data['list'];
      return forecastList.map((json) => Weather.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load forecast data');
    }
  }
}