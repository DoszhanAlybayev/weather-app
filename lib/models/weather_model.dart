
class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String iconCode; // Код иконки погоды
  final DateTime? dateTime; // Для прогноза

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.iconCode,
    this.dateTime,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // Проверяем наличие 'name' для текущей погоды или 'city.name' для прогноза
    String cityName = json['name'] ?? json['city']?['name'] ?? 'Unknown';

    // Для прогноза, 'dt' - это timestamp, для текущей погоды его может не быть
    DateTime? dateTime;
    if (json.containsKey('dt')) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000);
    }

    return Weather(
      cityName: cityName,
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      dateTime: dateTime,
    );
  }
}