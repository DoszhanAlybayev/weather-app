import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:weather_app/models/city_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:weather_app/pages/hourly_forecast_widget.dart';
import 'package:weather_app/pages/daily_forecast_widget.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/utils/weather_animation_utils.dart';
import 'dart:async';
import 'package:app_settings/app_settings.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  Timer? _debounce;
  StreamSubscription<ServiceStatus>? _locationServiceSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentLocationWeather();
    });
    _locationServiceSub = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.enabled) {
        _fetchCurrentLocationWeather();
      }
    });
    _cityController.addListener(_onCityControllerChanged);
    Intl.defaultLocale = 'ru';
  }

  void _onCityControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _locationServiceSub?.cancel();
    _debounce?.cancel();
    _cityController.removeListener(_onCityControllerChanged);
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocationWeather() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Службы геолокации отключены.'),
          duration: Duration(seconds: 10),
        ),
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      await Provider.of<WeatherProvider>(context, listen: false)
          .fetchWeatherAndForecastByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не удалось получить местоположение или загрузить погоду. Проверьте интернет и разрешения.'),
          action: SnackBarAction(
            label: 'Повторить',
            onPressed: () {
              _fetchCurrentLocationWeather();
            },
          ),
        ),
      );
      Provider.of<WeatherProvider>(context, listen: false).errorMessage = 'Ошибка загрузки данных по местоположению.';
      Provider.of<WeatherProvider>(context, listen: false).notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final _weather = weatherProvider.weather;
    final _forecast = weatherProvider.forecast;
    final _dailyForecast = weatherProvider.dailyForecast;
    final _cityName = weatherProvider.cityName;
    final _errorMessage = weatherProvider.errorMessage;
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
            onPressed: _fetchCurrentLocationWeather,
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
                          _errorMessage ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.red[700]),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: TypeAheadField<City>(
                          controller: _cityController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
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
                                  weatherProvider.fetchWeatherAndForecast(value);
                                  FocusScope.of(context).unfocus();
                                  _cityController.clear();
                                }
                              },
                            );
                          },
                          suggestionsCallback: (pattern) async {
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            final completer = Completer<List<City>>();
                            _debounce = Timer(const Duration(milliseconds: 500), () async {
                              if (pattern.isEmpty) {
                                completer.complete([]);
                              } else {
                                try {
                                  final result = await Provider.of<WeatherProvider>(context, listen: false).searchCities(pattern);
                                  completer.complete(result);
                                } catch (e) {
                                  completer.complete([]);
                                }
                              }
                            });
                            return completer.future;
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion.displayName),
                            );
                          },
                          onSelected: (suggestion) {
                            _cityController.text = suggestion.name;
                            weatherProvider.fetchWeatherAndForecast(suggestion.name);
                            FocusScope.of(context).unfocus();
                            _cityController.clear();
                          },
                          emptyBuilder: (context) => const SizedBox.shrink(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TypeAheadField<City>(
                        controller: _cityController,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
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
                                weatherProvider.fetchWeatherAndForecast(value);
                                FocusScope.of(context).unfocus();
                                _cityController.clear();
                              }
                            },
                          );
                        },
                        suggestionsCallback: (pattern) async {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          final completer = Completer<List<City>>();
                          _debounce = Timer(const Duration(milliseconds: 500), () async {
                            if (pattern.isEmpty) {
                              completer.complete([]);
                            } else {
                              try {
                                final result = await Provider.of<WeatherProvider>(context, listen: false).searchCities(pattern);
                                completer.complete(result);
                              } catch (e) {
                                completer.complete([]);
                              }
                            }
                          });
                          return completer.future;
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion.displayName),
                          );
                        },
                        onSelected: (suggestion) {
                          _cityController.text = suggestion.name;
                          weatherProvider.fetchWeatherAndForecast(suggestion.name);
                          FocusScope.of(context).unfocus();
                          _cityController.clear();
                        },
                        emptyBuilder: (context) => const SizedBox.shrink(),
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
                    Lottie.asset(WeatherAnimationUtils.getWeatherAnimation(_weather.weatherId), width: 200, height: 200),
                    const SizedBox(height: 15),
                    Text(
                      '${_weather.temperature.round()}°C',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _weather.mainCondition,
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 30),
                    HourlyForecastWidget(forecast: _forecast),
                    const SizedBox(height: 30),
                    if (_dailyForecast.isNotEmpty)
                      DailyForecastWidget(dailyForecast: _dailyForecast),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}