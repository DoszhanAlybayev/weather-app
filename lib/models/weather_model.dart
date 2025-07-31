
import 'package:flutter/foundation.dart'; // Добавим для debugPrint

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition; // Теперь это будет русское описание
  final String iconCode; // Код иконки погоды
  final DateTime? dateTime; // Для прогноза
  final int weatherId; // <--- НОВОЕ ПОЛЕ: для анимации по ID

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.iconCode,
    required this.weatherId, // <--- Обязательно в конструкторе
    this.dateTime,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    String cityName = json['name'] ?? json['city']?['name'] ?? 'Unknown';

    DateTime? dateTime;
    if (json.containsKey('dt')) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000);
    } else if (json.containsKey('dt_txt')) {
      try {
        dateTime = DateTime.parse(json['dt_txt']);
      } catch (e) {
        debugPrint('Error parsing dt_txt: $e');
      }
    }

    return Weather(
      cityName: cityName,
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['description'], // <--- ВОЗВРАЩАЕМ 'description' для русского текста
      iconCode: json['weather'][0]['icon'],
      weatherId: json['weather'][0]['id'], // <--- ПАРСИМ ID ДЛЯ АНИМАЦИИ
      dateTime: dateTime,
    );
  }
}