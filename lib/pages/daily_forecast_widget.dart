import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_app/utils/weather_animation_utils.dart';

class DailyForecastWidget extends StatelessWidget {
  final List<Weather> dailyForecast;
  const DailyForecastWidget({Key? key, required this.dailyForecast}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прогноз на 4 дня:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...dailyForecast.map((item) {
          final dateString = DateFormat('dd MMMM', 'ru').format(item.dateTime!);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: ListTile(
              leading: Lottie.asset(
                WeatherAnimationUtils.getWeatherAnimation(item.weatherId),
                width: 40,
                height: 40,
              ),
              title: Text(dateString),
              subtitle: Text(item.mainCondition),
              trailing: Text(
                '${item.minTemperature?.round() ?? '-'}° / ${item.maxTemperature?.round() ?? '-'}°C',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
