import 'package:dio/dio.dart';

import '../domain/location.dart';
import '../domain/weather.dart';

abstract interface class WeatherRepository {
  Future<Weather> fetch(Location location, CancelToken token);
}

class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository(this.dio);
  final Dio dio;
  @override
  Future<Weather> fetch(Location location, CancelToken token) async {
    final response = await dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': 7,
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
      },
      cancelToken: token,
    );
    if (response.data == null) throw const FormatException('天气响应为空');
    return Weather.fromJson(response.data!);
  }
}

String errorMessage(Object error) {
  if (error is FormatException || error is TypeError) return '天气数据格式异常，请重试';
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => '请求超时，请重试',
      DioExceptionType.badResponse =>
        error.response?.statusCode == 429 ? '请求过于频繁，请稍后重试' : '天气服务暂不可用，请稍后重试',
      _ => '网络连接失败，请检查网络后重试',
    };
  }
  return '无法加载天气，请重试';
}
