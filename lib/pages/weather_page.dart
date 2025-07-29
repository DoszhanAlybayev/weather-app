// lib/pages/weather_page.dart
import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:lottie/lottie.dart'; // Убедитесь, что Lottie импортирован

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService();
  Weather? _weather; // Текущая погода
  List<Weather>? _forecast; // Прогноз погоды
  String _cityName = "Almaty"; // Город по умолчанию при запуске

  final TextEditingController _cityController = TextEditingController(); // Контроллер для поля поиска

  String? _errorMessage; // Переменная для хранения сообщения об ошибке

  @override
  void initState() {
    super.initState();
    // Загружаем погоду и прогноз для города по умолчанию при старте страницы
    _fetchWeatherAndForecast(_cityName);
  }

  @override
  void dispose() {
    _cityController.dispose(); // Освобождаем контроллер при уничтожении виджета
    super.dispose();
  }

  // Метод для получения текущей погоды и прогноза
  _fetchWeatherAndForecast(String cityName) async {
    setState(() {
      _weather = null; // Сбрасываем данные текущей погоды для показа индикатора загрузки
      _forecast = null; // Сбрасываем данные прогноза
      _errorMessage = null; // Сбрасываем предыдущие ошибки
    });
    try {
      final current = await _weatherService.getWeather(cityName);
      final forecast = await _weatherService.getForecast(cityName);

      setState(() {
        _weather = current;
        _forecast = forecast;
        _cityName = current.cityName; // Обновляем имя города из ответа API (может отличаться от введенного)
      });
    } catch (e) {
      print("Ошибка при загрузке погоды: $e"); // Вывод ошибки в консоль для отладки
      setState(() {
        _weather = null; // Очищаем данные, чтобы показать сообщение об ошибке
        _forecast = null;
        // Определяем более конкретное сообщение об ошибке
        if (e.toString().contains('404')) { // Если ошибка 404 (Not Found)
          _errorMessage = 'Город не найден. Пожалуйста, проверьте название.';
        } else {
          _errorMessage = 'Не удалось загрузить данные о погоде. Проверьте подключение к Интернету.';
        }
      });
      // Показываем SnackBar с сообщением об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  // Метод для определения пути к Lottie-анимации на основе погодного условия
String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/animations/sunny.json'; // По умолчанию

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

  // Метод для получения URL иконки погоды (используется как запасной, если нет Lottie)
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
      body: Center( // Центрируем весь контент по горизонтали
        child: (_weather == null || _forecast == null) // Если данных нет
            ? (_errorMessage != null // И есть сообщение об ошибке
                ? Column( // Показываем UI с ошибкой
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
                      // Поле поиска дублируется здесь, чтобы оно всегда было видно
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
                                  _fetchWeatherAndForecast(_cityController.text);
                                  FocusScope.of(context).unfocus();
                                  _cityController.clear(); // Очищаем поле после поиска
                                }
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _fetchWeatherAndForecast(value);
                              FocusScope.of(context).unfocus();
                              _cityController.clear(); // Очищаем поле после поиска
                            }
                          },
                        ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator() // Иначе, если данных нет, но и ошибки нет, значит, идет загрузка
              )
            : SingleChildScrollView( // Если данные успешно загружены, показываем основной UI
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Выравнивание по верху
                  crossAxisAlignment: CrossAxisAlignment.center, // Центрирование по горизонтали
                  children: [
                    const SizedBox(height: 40), // Отступ сверху

                    // Поле для поиска города
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
                                _fetchWeatherAndForecast(_cityController.text);
                                FocusScope.of(context).unfocus(); // Скрыть клавиатуру
                                _cityController.clear(); // Очистить поле
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                        ),
                        onSubmitted: (value) { // Поиск по нажатию Enter
                          if (value.isNotEmpty) {
                            _fetchWeatherAndForecast(value);
                            FocusScope.of(context).unfocus(); // Скрыть клавиатуру
                            _cityController.clear(); // Очистить поле
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 30), // Отступ после TextField

                    // Название города
                    Text(
                      _cityName, // Используем _cityName из состояния
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // Lottie Анимация текущей погоды
                    Lottie.asset(getWeatherAnimation(_weather!.mainCondition), width: 200, height: 200),

                    const SizedBox(height: 15),

                    // Температура текущей погоды
                    Text(
                      '${_weather!.temperature.round()}°C',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),

                    // Основное состояние текущей погоды
                    Text(
                      _weather!.mainCondition,
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 30), // Отступ перед прогнозом

                    // Заголовок прогноза погоды
                    const Text(
                      'Прогноз на ближайшие часы:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    // Горизонтальный список прогноза
                    SizedBox( // Ограничиваем высоту ListView.builder
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Горизонтальная прокрутка
                        itemCount: _forecast!.length > 8 ? 8 : _forecast!.length, // Показываем до 8 элементов (24 часа)
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
                            child: Container( // Контейнер для фиксированной ширины карточки
                              width: 120,
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    timeString, // Время прогноза
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    dayString, // Дата прогноза
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
                                    '${forecastItem.temperature.round()}°C', // Температура прогноза
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Expanded( // Позволяет тексту описания занимать доступное пространство
                                    child: Text(
                                      forecastItem.mainCondition,
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis, // Обрезает текст, если не помещается
                                      maxLines: 2, // Максимум 2 строки
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20), // Отступ в конце
                  ],
                ),
              ),
      ),
    );
  }
}