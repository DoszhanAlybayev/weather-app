import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:lottie/lottie.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  Weather? _weather;
  //город по умолчанию
  String _cityName = "Shymkent";

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeather(_cityName);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  _fetchWeather(String cityName) async {
    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
        _cityName = weather.cityName;
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки погоды: ${e.toString()}')),
      );
      setState(() {
        _weather = null;
      });
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/animations/cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/animations/rainy.json';
      case 'thunderstorm':
        return 'assets/animations/thunder.json';
      case 'clear':
        return 'assets/animations/sunny.json';
      case 'snow':
        return 'assets/animations/snowy.json';
      default:
        return 'assets/animations/sunny.json';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Погода'),
        centerTitle: true,
      ),
      body: Center(
        child: _weather == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'Введите название города',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            if (_cityController.text.isNotEmpty) {
                              _fetchWeather(_cityController.text);
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (value) { // Поиск по нажатию Enter
                        if (value.isNotEmpty) {
                          _fetchWeather(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20), 

                  // Название города
                  Text(
                    _cityName, // Используем _cityName из состояния
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Lottie Анимация
                  Lottie.asset(getWeatherAnimation(_weather!.mainCondition)),

                  const SizedBox(height: 10),

                  // Температура
                  Text(
                    '${_weather!.temperature.round()}°C',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 10),

                  // Основное состояние погоды
                  Text(
                    _weather!.mainCondition,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),

                  // Кнопка для обновления (можно убрать, если есть поиск)
                  // ElevatedButton(
                  //   onPressed: () => _fetchWeather(_cityName),
                  //   child: const Text('Обновить погоду'),
                  // ),
                ],
              ),
      ),
    );
  }
}