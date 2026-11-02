import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/weather_page.dart';

void main() => runApp(const ProviderScope(child: WeatherApp()));

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '天气',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff1e6261),
        surface: const Color(0xfff5f5ef),
      ),
      fontFamilyFallback: const ['PingFang SC', 'Noto Sans CJK SC'],
    ),
    home: const WeatherPage(),
  );
}
