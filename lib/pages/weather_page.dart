// lib/pages/weather_page.dart
import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:weather_app/models/city_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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
    _cityController.addListener(_onCityControllerChanged);
  }

  void _onCityControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _cityController.removeListener(_onCityControllerChanged);
    _cityController.dispose();
    super.dispose();
  }

  // Метод для получения текущей погоды и прогноза по названию города
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
        print("API mainCondition (by city, text): ${_weather!.mainCondition}"); // Будет на русском
        print("API weatherId (by city, for animation): ${_weather!.weatherId}"); // Число для анимации
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

  // Метод для получения погоды по координатам
  _fetchWeatherAndForecastByCoordinates(double lat, double lon) async {
    setState(() {
      _weather = null;
      _forecast = null;
      _errorMessage = null;
    });
    try {
      final current = await _weatherService.getWeatherByCoordinates(lat, lon);
      final forecast = await _weatherService.getForecastByCoordinates(lat, lon);

      setState(() {
        _weather = current;
        _forecast = forecast;
        _cityName = current.cityName;
        print("API mainCondition (by coords, text): ${_weather!.mainCondition}"); // Будет на русском
        print("API weatherId (by coords, for animation): ${_weather!.weatherId}"); // Число для анимации
      });
    } catch (e) {
      print("Ошибка при загрузке погоды по координатам: $e");
      setState(() {
        _weather = null;
        _forecast = null;
        _errorMessage = 'Не удалось загрузить данные о погоде по местоположению.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  // НОВЫЙ МЕТОД (восстановленный): Получение текущего местоположения пользователя
  _fetchCurrentLocationWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Службы геолокации отключены.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешение на местоположение отклонено.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Разрешение на местоположение отклонено навсегда. Пожалуйста, измените в настройках.')),
      );
      return;
    }

    try {
      setState(() {
        _weather = null;
        _forecast = null;
        _errorMessage = null;
      });
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      await _fetchWeatherAndForecastByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      print("Ошибка при получении местоположения: $e");
      setState(() {
        _errorMessage = 'Не удалось получить текущее местоположение.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  // ОБНОВЛЕННАЯ ФУНКЦИЯ: ИСПОЛЬЗУЕМ weatherId
  String getWeatherAnimation(int weatherId) {
    // OpenWeatherMap ID ranges:
    // 2xx Thunderstorm
    // 3xx Drizzle
    // 5xx Rain
    // 6xx Snow
    // 7xx Atmosphere (Mist, Smoke, Haze, Dust, Fog, Sand, Ash, Squall, Tornado)
    // 800 Clear
    // 801-804 Clouds

    if (weatherId >= 200 && weatherId <= 232) {
      return 'assets/animations/thunder.json'; // Гроза
    } else if (weatherId >= 300 && weatherId <= 321) {
      return 'assets/animations/rainy.json'; // Морось
    } else if (weatherId >= 500 && weatherId <= 531) {
      return 'assets/animations/rainy.json'; // Дождь
    } else if (weatherId >= 600 && weatherId <= 622) {
      return 'assets/animations/snowy.json'; // Снег
    } else if (weatherId >= 701 && weatherId <= 781) {
      return 'assets/animations/cloudy.json'; // Атмосферные явления (туман, дымка и т.д.)
    } else if (weatherId == 800) {
      return 'assets/animations/sunny.json'; // Ясное небо
    } else if (weatherId >= 801 && weatherId <= 804) {
      return 'assets/animations/cloudy.json'; // Облака
    } else {
      print("Unknown weather ID: $weatherId. Defaulting to sunny animation.");
      return 'assets/animations/sunny.json';
    }
  }

  String getWeatherIconUrl(String iconCode) {
    return 'http://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy', 'ru').format(now);
    final formattedTime = DateFormat('HH:mm').format(now);
    final dateTimeString = '$formattedDate, $formattedTime';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Погода'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              _fetchCurrentLocationWeather(); // <--- ЭТОТ МЕТОД ТЕПЕРЬ ЕСТЬ
            },
            tooltip: 'Мое местоположение',
          ),
        ],
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
                          controller: _cityController,
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
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          controller.clear();
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
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
                        controller: _cityController,
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
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        controller.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
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
                    const SizedBox(height: 5),
                    Text(
                      dateTimeString,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 15),
                    Lottie.asset(getWeatherAnimation(_weather!.weatherId), width: 200, height: 200),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 230,
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
                              width: 135,
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
                                    getWeatherAnimation(forecastItem.weatherId),
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
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
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