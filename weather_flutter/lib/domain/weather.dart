double? _number(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;
int? _code(Object? value) =>
    value is num && value.isFinite ? value.toInt() : null;

class CurrentWeather {
  const CurrentWeather({
    this.temperature,
    this.apparent,
    this.humidity,
    this.wind,
    this.code,
    this.localTime = '',
  });
  final double? temperature, apparent, humidity, wind;
  final int? code;
  final String localTime;
}

class ForecastDay {
  const ForecastDay({
    required this.date,
    this.code,
    this.high,
    this.low,
    this.rain,
  });
  final String date;
  final int? code;
  final double? high, low, rain;
}

class Weather {
  const Weather({
    required this.current,
    required this.days,
    required this.timezone,
  });
  final CurrentWeather current;
  final List<ForecastDay> days;
  final String timezone;
  factory Weather.fromJson(Map<String, dynamic> json) {
    if (json['current'] is! Map || json['daily'] is! Map) {
      throw const FormatException('天气数据不完整');
    }
    final current = Map<String, dynamic>.from(json['current'] as Map);
    final daily = Map<String, dynamic>.from(json['daily'] as Map);
    final dates = daily['time'];
    if (dates is! List ||
        dates.isEmpty ||
        dates.any(
          (d) =>
              d is! String ||
              !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d) ||
              DateTime.tryParse(d) == null,
        )) {
      throw const FormatException('预报日期无效');
    }
    Object? at(String key, int i) {
      final list = daily[key];
      return list is List && i < list.length ? list[i] : null;
    }

    return Weather(
      current: CurrentWeather(
        temperature: _number(current['temperature_2m']),
        apparent: _number(current['apparent_temperature']),
        humidity: _number(current['relative_humidity_2m']),
        wind: _number(current['wind_speed_10m']),
        code: _code(current['weather_code']),
        localTime: current['time'] as String? ?? '',
      ),
      days: List.generate(
        dates.length,
        (i) => ForecastDay(
          date: dates[i] as String,
          code: _code(at('weather_code', i)),
          high: _number(at('temperature_2m_max', i)),
          low: _number(at('temperature_2m_min', i)),
          rain: _number(at('precipitation_probability_max', i)),
        ),
      ),
      timezone: json['timezone'] as String? ?? '当地时间',
    );
  }
}

String weatherDescription(int? code) => switch (code) {
  0 => '晴',
  1 || 2 => '晴间多云',
  3 => '阴',
  45 || 48 => '雾',
  51 || 53 || 55 || 56 || 57 => '毛毛雨',
  61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => '雨',
  71 || 73 || 75 || 77 || 85 || 86 => '雪',
  95 || 96 || 99 => '雷雨',
  _ => '天气未知',
};
