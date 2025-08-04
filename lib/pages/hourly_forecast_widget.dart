import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_app/utils/weather_animation_utils.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<Weather> forecast;
  const HourlyForecastWidget({Key? key, required this.forecast}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecast.length > 8 ? 8 : forecast.length,
        itemBuilder: (context, index) {
          final forecastItem = forecast[index];
          final itemDateTime = forecastItem.dateTime!;
          final timeString = "${itemDateTime.hour.toString().padLeft(2, '0')}:00";
          String dayString;
          final now = DateTime.now();
          final forecastDate = itemDateTime;
          if (forecastDate.day == now.day && forecastDate.month == now.month && forecastDate.year == now.year) {
            dayString = 'Сегодня';
          } else if (forecastDate.difference(now).inDays == 1 ||
                     (now.hour > 12 && forecastDate.day == now.add(Duration(days: 1)).day)) {
            dayString = 'Завтра';
          } else {
            dayString = DateFormat('dd.MM.yy').format(forecastDate);
          }
          return SizedBox(
            width: 160,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dayString, style: const TextStyle(fontSize: 16)),
                    Text(timeString, style: const TextStyle(fontSize: 16)),
                    Lottie.asset(
                      WeatherAnimationUtils.getWeatherAnimation(forecastItem.weatherId),
                      width: 50,
                      height: 50,
                    ),
                    Text('${forecastItem.temperature.round()}°C', style: const TextStyle(fontSize: 20)),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        forecastItem.mainCondition,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
