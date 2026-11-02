import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/weather.dart';
import '../state/weather_controller.dart';

class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});
  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends ConsumerState<WeatherPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(weatherControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weatherControllerProvider);
    final controller = ref.read(weatherControllerProvider.notifier);
    final weather = state.weather;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回城市搜索',
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.close,
        ),
        title: const Text('天气详情'),
        actions: [
          IconButton(
            tooltip: '刷新天气',
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: weather == null
                ? _InitialState(state: state, retry: controller.load)
                : RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      children: [
                        if (state.loading) const LinearProgressIndicator(),
                        if (state.error != null)
                          _Notice(
                            message: state.error!,
                            retry: controller.load,
                          ),
                        if (state.bridgeWarning != null)
                          _Notice(
                            message: state.bridgeWarning!,
                            retry: controller.load,
                          ),
                        Text(
                          state.context!.location.name,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.context!.location.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final current = CurrentWeatherCard(
                              weather: weather,
                            );
                            final forecast = ForecastCard(days: weather.days);
                            if (constraints.maxWidth >= 700) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: current),
                                  const SizedBox(width: 20),
                                  Expanded(child: forecast),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                current,
                                const SizedBox(height: 24),
                                forecast,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '地点时区：${weather.timezone}\n天气数据：Open-Meteo · CC BY 4.0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState({required this.state, required this.retry});
  final WeatherState state;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.loading || state.error == null) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('正在获取天气…'),
        ] else ...[
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          Text(state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: retry, child: const Text('重试')),
        ],
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(message),
        TextButton(onPressed: retry, child: const Text('重试')),
      ],
    ),
  );
}

String valueLabel(double? value, String unit) =>
    value == null ? '—' : '${value.round()}$unit';

IconData weatherIcon(int? code) => switch (code) {
  0 => Icons.wb_sunny_outlined,
  1 || 2 => Icons.wb_cloudy_outlined,
  3 => Icons.cloud_outlined,
  45 || 48 => Icons.foggy,
  51 ||
  53 ||
  55 ||
  56 ||
  57 ||
  61 ||
  63 ||
  65 ||
  66 ||
  67 ||
  80 ||
  81 ||
  82 => Icons.umbrella_outlined,
  71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
  95 || 96 || 99 => Icons.thunderstorm_outlined,
  _ => Icons.help_outline,
};

class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({super.key, required this.weather});
  final Weather weather;
  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xff163f40),
        borderRadius: BorderRadius.circular(28),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前天气',
              style: TextStyle(fontSize: 16, color: Color(0xffb6d7ca)),
            ),
            const SizedBox(height: 18),
            Icon(weatherIcon(current.code), size: 56, color: Colors.white),
            Text(
              valueLabel(current.temperature, '°'),
              style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w300),
            ),
            Text(
              weatherDescription(current.code),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                Text('体感  ${valueLabel(current.apparent, '°C')}'),
                Text('湿度  ${valueLabel(current.humidity, '%')}'),
                Text('风速  ${valueLabel(current.wind, ' km/h')}'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '数据时间 ${current.localTime.replaceFirst('T', ' ')}\n地点当地时间',
              style: const TextStyle(color: Color(0xffb6d7ca), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key, required this.days});
  final List<ForecastDay> days;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        identifier: 'forecast-heading',
        header: true,
        child: Text(
          '未来 7 天',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 12),
      for (final day in days)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Semantics(
            label: '${day.date} ${weatherDescription(day.code)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(day.date.substring(5).replaceFirst('-', '/')),
                    Icon(weatherIcon(day.code), size: 24),
                    Text(weatherDescription(day.code)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  children: [
                    Text(
                      '${valueLabel(day.low, '°')} / ${valueLabel(day.high, '°')}',
                    ),
                    Text(
                      '降水 ${valueLabel(day.rain, '%')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      const Divider(),
      const Text('最低 / 最高温度 · 右侧为降水概率'),
    ],
  );
}
