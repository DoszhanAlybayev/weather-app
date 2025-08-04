import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/models/city_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static const BASE_URL = 'http://api.openweathermap.org/data/2.5';
  final String apiKey;

  WeatherService() : apiKey = dotenv.env['OPEN_WEATHER_API_KEY']!;

  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(Uri.parse('$BASE_URL/weather?q=$cityName&appid=$apiKey&units=metric&lang=ru'));
    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Не удалось загрузить данные о погоде для $cityName');
    }
  }

  Future<List<Weather>> getForecast(String cityName) async {
    final response = await http.get(Uri.parse('$BASE_URL/forecast?q=$cityName&appid=$apiKey&units=metric&lang=ru'));
    if (response.statusCode == 200) {
      List<dynamic> forecastList = jsonDecode(response.body)['list'];
      return forecastList.map((json) => Weather.fromJson(json)).toList();
    } else {
      throw Exception('Не удалось загрузить прогноз погоды для $cityName');
    }
  }

  Future<List<City>> searchCities(String query) async {
    String kzQuery = query.trim();
    if (!kzQuery.toLowerCase().endsWith(',kz')) {
      kzQuery += ',KZ';
    }
    final responseKZ = await http.get(Uri.parse('http://api.openweathermap.org/geo/1.0/direct?q=$kzQuery&limit=10&appid=$apiKey&lang=ru'));
    List<City> kzCities = [];
    if (responseKZ.statusCode == 200) {
      List<dynamic> cityDataKZ = jsonDecode(responseKZ.body);
      kzCities = cityDataKZ.map((json) => City.fromJson(json)).toList();
    }
    if (kzCities.isNotEmpty) {
      return kzCities;
    }
    final response = await http.get(Uri.parse('http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=10&appid=$apiKey&lang=ru'));
    if (response.statusCode == 200) {
      List<dynamic> cityData = jsonDecode(response.body);
      List<City> allCities = cityData.map((json) => City.fromJson(json)).toList();
      List<City> kzCities = allCities.where((c) => c.country.toUpperCase() == 'KZ').toList();
      List<City> otherCities = allCities.where((c) => c.country.toUpperCase() != 'KZ').toList();
      return [...kzCities, ...otherCities];
    } else {
      throw Exception('Не удалось найти города.');
    }
  }

  Future<Weather> getWeatherByCoordinates(double lat, double lon) async {
    final response = await http.get(Uri.parse('$BASE_URL/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ru'));
    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Не удалось загрузить данные о погоде по координатам');
    }
  }

  Future<List<Weather>> getForecastByCoordinates(double lat, double lon) async {
    final response = await http.get(Uri.parse('$BASE_URL/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ru'));
    if (response.statusCode == 200) {
      List<dynamic> forecastList = jsonDecode(response.body)['list'];
      return forecastList.map((json) => Weather.fromJson(json)).toList();
    } else {
      throw Exception('Не удалось загрузить прогноз погоды по координатам');
    }
  }

  Future<String> reverseGeocode(double lat, double lon) async {
    final response = await http.get(Uri.parse('http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey&lang=ru'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['name'] != null) {
        return data[0]['name'];
      }
      return 'Неизвестно';
    } else {
      return 'Неизвестно';
    }
  }
}