// lib/pages/weather_page.dart
import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:weather_app/models/city_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  Weather? _weather;
  List<Weather>? _forecast; // 3-часовой прогноз
  List<Weather>? _dailyForecast; // Дневной прогноз
  String _cityName = "Almaty";

  final TextEditingController _cityController = TextEditingController();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWeatherAndForecast(_cityName);
    _cityController.addListener(_onCityControllerChanged);
    Intl.defaultLocale = 'ru';
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

  // Метод для обработки 3-часового прогноза и формирования дневного
  List<Weather> _processDailyForecast(List<Weather> hourlyForecast) {
    if (hourlyForecast.isEmpty) return [];

    final Map<String, List<Weather>> dailyGroupedForecast = {};
    for (var item in hourlyForecast) {
      // Группируем по дате (без времени)
      final dateKey = DateFormat('yyyy-MM-dd').format(item.dateTime!);
      if (!dailyGroupedForecast.containsKey(dateKey)) {
        dailyGroupedForecast[dateKey] = [];
      }
      dailyGroupedForecast[dateKey]!.add(item);
    }

    final List<Weather> processedDailyForecast = [];
    final now = DateTime.now();
    // Нормализуем текущую дату до начала дня для сравнения
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    dailyGroupedForecast.forEach((dateKey, dayItems) {
      // Игнорируем сегодняшний день, так как его погода уже отображается отдельно
      if (dateKey == todayKey) {
        return;
      }

      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      Weather? mainDayWeather; // Погода, наиболее репрезентативная для дня

      // Сортируем элементы по времени для удобства
      dayItems.sort((a, b) => a.dateTime!.compareTo(b.dateTime!));

      for (var item in dayItems) {
        minTemp = min(minTemp, item.temperature);
        maxTemp = max(maxTemp, item.temperature);

        // Пытаемся найти прогноз на полдень (12:00) или ближайшее к нему время
        // Если уже есть mainDayWeather, обновляем только если текущий элемент ближе к 12:00
        if (mainDayWeather == null ||
            (item.dateTime!.hour - 12).abs() < (mainDayWeather.dateTime!.hour - 12).abs()) {
          mainDayWeather = item;
        }
      }

      if (mainDayWeather != null) {
        processedDailyForecast.add(
          Weather(
            cityName: mainDayWeather.cityName,
            temperature: mainDayWeather.temperature, // Оставляем температуру из выбранного "основного" прогноза
            mainCondition: mainDayWeather.mainCondition,
            iconCode: mainDayWeather.iconCode,
            weatherId: mainDayWeather.weatherId,
            dateTime: mainDayWeather.dateTime,
            minTemperature: minTemp, // <--- Заполняем минимальную температуру
            maxTemperature: maxTemp, // <--- Заполняем максимальную температуру
          ),
        );
      }
    });

    // Сортируем дневной прогноз по дате
    processedDailyForecast.sort((a, b) => a.dateTime!.compareTo(b.dateTime!));

    // Оставляем только 4 дня вперед (без сегодняшнего)
    return processedDailyForecast.take(4).toList();
  }

  _fetchWeatherAndForecast(String cityName) async {
    setState(() {
      _weather = null;
      _forecast = null;
      _dailyForecast = null;
      _errorMessage = null;
    });
    try {
      final current = await _weatherService.getWeather(cityName);
      final forecast = await _weatherService.getForecast(cityName);
      final daily = _processDailyForecast(forecast);

      setState(() {
        _weather = current;
        _forecast = forecast;
        _dailyForecast = daily;
        _cityName = current.cityName;
        print("API mainCondition (by city, text): ${_weather!.mainCondition}");
        print("API weatherId (by city, for animation): ${_weather!.weatherId}");
      });
    } catch (e) {
      print("Ошибка при загрузке погоды: $e");
      setState(() {
        _weather = null;
        _forecast = null;
        _dailyForecast = null;
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

  _fetchWeatherAndForecastByCoordinates(double lat, double lon) async {
    setState(() {
      _weather = null;
      _forecast = null;
      _dailyForecast = null;
      _errorMessage = null;
    });
    try {
      final current = await _weatherService.getWeatherByCoordinates(lat, lon);
      final forecast = await _weatherService.getForecastByCoordinates(lat, lon);
      final daily = _processDailyForecast(forecast);

      setState(() {
        _weather = current;
        _forecast = forecast;
        _dailyForecast = daily;
        _cityName = current.cityName;
        print("API mainCondition (by coords, text): ${_weather!.mainCondition}");
        print("API weatherId (by coords, for animation): ${_weather!.weatherId}");
      });
    } catch (e) {
      print("Ошибка при загрузке погоды по координатам: $e");
      setState(() {
        _weather = null;
        _forecast = null;
        _dailyForecast = null;
        _errorMessage = 'Не удалось загрузить данные о погоде по местоположению.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

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
        _dailyForecast = null;
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

  String getWeatherAnimation(int weatherId) {
    if (weatherId >= 200 && weatherId <= 232) {
      return 'assets/animations/thunder.json';
    } else if (weatherId >= 300 && weatherId <= 321) {
      return 'assets/animations/rainy.json';
    } else if (weatherId >= 500 && weatherId <= 531) {
      return 'assets/animations/rainy.json';
    } else if (weatherId >= 600 && weatherId <= 622) {
      return 'assets/animations/snowy.json';
    } else if (weatherId >= 701 && weatherId <= 781) {
      return 'assets/animations/cloudy.json';
    } else if (weatherId == 800) {
      return 'assets/animations/sunny.json';
    } else if (weatherId >= 801 && weatherId <= 804) {
      return 'assets/animations/cloudy.json';
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
              _fetchCurrentLocationWeather();
            },
            tooltip: 'Мое местоположение',
          ),
        ],
      ),
      body: Center(
        child: (_weather == null || _forecast == null || _dailyForecast == null)
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
                        padding: const EdgeInsets.symmetric(horizontal: 20.0), // <-- Изменено
                        child: TypeAheadField<City>(
                          controller: _cityController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration( // <-- Изменено
                                hintText: 'Введите название города',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.grey[200],
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: Colors.grey[600]),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0), // <-- Изменено
                      child: TypeAheadField<City>(
                        controller: _cityController,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration( // <-- Изменено
                              hintText: 'Введите название города',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[200],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[600]),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              width: 130,
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
                                      style: const TextStyle(fontSize: 12),
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
                    const SizedBox(height: 30),
                    if (_dailyForecast != null && _dailyForecast!.isNotEmpty)
                      const Text(
                        'Прогноз на несколько дней:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 15),
                    Column(
                      children: _dailyForecast!.map((dayForecast) {
                        final dayOfWeek = DateFormat('EEEE', 'ru').format(dayForecast.dateTime!);
                        final date = DateFormat('dd MMMM', 'ru').format(dayForecast.dateTime!);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dayOfWeek,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    Text(
                                      date,
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dayForecast.mainCondition,
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.left,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Lottie.asset(
                                  getWeatherAnimation(dayForecast.weatherId),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Макс: ${dayForecast.maxTemperature?.round()}°C',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Мин: ${dayForecast.minTemperature?.round()}°C',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}