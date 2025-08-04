class WeatherAnimationUtils {
  static String getWeatherAnimation(int weatherId) {
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
      return 'assets/animations/sunny.json';
    }
  }
}
