
import 'package:flutter/foundation.dart';

class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String iconCode;
  final DateTime? dateTime;
  final int weatherId;
  final double? minTemperature;
  final double? maxTemperature; 

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.iconCode,
    required this.weatherId,
    this.dateTime,
    this.minTemperature,
    this.maxTemperature, 
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
      mainCondition: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      weatherId: json['weather'][0]['id'],
      dateTime: dateTime,
      minTemperature: null, // По умолчанию null
      maxTemperature: null, // По умолчанию null
    );
  }
}