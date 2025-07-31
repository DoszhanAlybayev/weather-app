// lib/pages/weather_page.dart
import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:weather_app/models/city_model.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  Weather? _weather;
  List<Weather>? _forecast;
  String _cityName = "Almaty";

  final TextEditingController _cityController = TextEditingController();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWeatherAndForecast(_cityName);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  _fetchWeatherAndForecast(String cityName) async {
    setState(() {
      _weather = null;
      _forecast = null;
      _errorMessage = null;
    });
    try {
      final current = await _weatherService.getWeather(cityName);
      final forecast = await _weatherService.getForecast(cityName);

      setState(() {
        _weather = current;
        _forecast = forecast;
        _cityName = current.cityName;
      });
    } catch (e) {
      print("Ошибка при загрузке погоды: $e");
      setState(() {
        _weather = null;
        _forecast = null;
        if (e.toString().contains('404')) {
          _errorMessage = 'Город не найден. Пожалуйста, проверьте название.';
        } else {
          _errorMessage = 'Не удалось загрузить данные о погоде. Проверьте подключение к Интернету.';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/animations/sunny.json';

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

  String getWeatherIconUrl(String iconCode) {
    return 'http://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Погода'),
        centerTitle: true,
      ),
      body: Center(
        child: (_weather == null || _forecast == null)
            ? (_errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.red[700]),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: TypeAheadField<City>(
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Введите название города',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  _fetchWeatherAndForecast(value);
                                  FocusScope.of(context).unfocus();
                                  _cityController.clear();
                                }
                              },
                            );
                          },
                          // УДАЛЕНО: minCharsForSuggestions
                          suggestionsCallback: (pattern) async {
                            if (pattern.isEmpty) return [];
                            try {
                              return await _weatherService.searchCities(pattern);
                            } catch (e) {
                              print("Ошибка при поиске городов: $e");
                              return [];
                            }
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion.displayName),
                            );
                          },
                          onSelected: (suggestion) {
                            _cityController.text = suggestion.name;
                            _fetchWeatherAndForecast(suggestion.name);
                            FocusScope.of(context).unfocus();
                            _cityController.clear();
                          },
                        ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator()
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TypeAheadField<City>(
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Введите название города',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _fetchWeatherAndForecast(value);
                                FocusScope.of(context).unfocus();
                                _cityController.clear();
                              }
                            },
                          );
                        },
                        // УДАЛЕНО: minCharsForSuggestions
                        suggestionsCallback: (pattern) async {
                          if (pattern.isEmpty) return [];
                          try {
                            return await _weatherService.searchCities(pattern);
                          } catch (e) {
                            print("Ошибка при поиске городов: $e");
                            return [];
                          }
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion.displayName),
                          );
                        },
                        onSelected: (suggestion) {
                          _cityController.text = suggestion.name;
                          _fetchWeatherAndForecast(suggestion.name);
                          FocusScope.of(context).unfocus();
                          _cityController.clear();
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _cityName,
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Lottie.asset(getWeatherAnimation(_weather!.mainCondition), width: 200, height: 200),
                    const SizedBox(height: 15),
                    Text(
                      '${_weather!.temperature.round()}°C',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _weather!.mainCondition,
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Прогноз на ближайшие часы:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _forecast!.length > 8 ? 8 : _forecast!.length,
                        itemBuilder: (context, index) {
                          final forecastItem = _forecast![index];
                          final itemDateTime = forecastItem.dateTime!;
                          final timeString = "${itemDateTime.hour.toString().padLeft(2, '0')}:00";
                          final dayString = "${itemDateTime.day}.${itemDateTime.month}";

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    timeString,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    dayString,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Lottie.asset(
                                    getWeatherAnimation(forecastItem.mainCondition),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${forecastItem.temperature.round()}°C',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      forecastItem.mainCondition,
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}