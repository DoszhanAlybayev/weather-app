// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- НОВЫЙ ИМПОРТ

import 'pages/weather_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Убеждаемся, что Flutter инициализирован

  // Инициализируем данные локали для русского языка
  // 'ru' - код локали
  // null - означает, что будут использоваться данные по умолчанию
  await initializeDateFormatting('ru', null); // <-- НОВЫЙ ВЫЗОВ ФУНКЦИИ

  // Загружаем переменные окружения из .env файла
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WeatherPage(),
    );
  }
}