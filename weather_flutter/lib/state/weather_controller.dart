import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bridge/host_bridge.dart';
import '../data/weather_repository.dart';
import '../domain/location.dart';
import '../domain/weather.dart';

final hostBridgeProvider = Provider<HostBridge>(
  (ref) => const MethodChannelHostBridge(),
);
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return OpenMeteoWeatherRepository(dio);
});
final weatherControllerProvider =
    NotifierProvider<WeatherController, WeatherState>(WeatherController.new);

class WeatherState {
  const WeatherState({
    this.context,
    this.weather,
    this.loading = false,
    this.error,
    this.bridgeWarning,
  });
  final LaunchContext? context;
  final Weather? weather;
  final bool loading;
  final String? error, bridgeWarning;
}

class WeatherController extends Notifier<WeatherState> {
  CancelToken? _token;
  bool _disposed = false, _reported = false;
  int _generation = 0;
  @override
  WeatherState build() {
    ref.onDispose(() {
      _disposed = true;
      _token?.cancel('Page closed');
    });
    return const WeatherState();
  }

  Future<void> load() async {
    final generation = ++_generation;
    _token?.cancel('Replaced by newer request');
    final token = _token = CancelToken();
    state = WeatherState(
      context: state.context,
      weather: state.weather,
      loading: true,
      bridgeWarning: state.bridgeWarning,
    );
    bool active() => !_disposed && generation == _generation;
    LaunchContext? context = state.context;
    if (context == null) {
      try {
        context = await ref.read(hostBridgeProvider).launchContext();
      } catch (_) {
        if (active()) state = const WeatherState(error: '无法读取城市参数，请返回重新选择');
        return;
      }
    }
    if (!active()) return;
    state = WeatherState(
      context: context,
      weather: state.weather,
      loading: true,
    );
    try {
      final weather = await ref
          .read(weatherRepositoryProvider)
          .fetch(context.location, token);
      if (!active()) return;
      state = WeatherState(context: context, weather: weather);
    } catch (error) {
      if (!active() || token.isCancelled) return;
      state = WeatherState(
        context: context,
        weather: state.weather,
        error: errorMessage(error),
      );
      return;
    }
    if (!_reported && active()) {
      try {
        await ref.read(hostBridgeProvider).weatherLoaded(context.sessionId);
        if (active()) _reported = true;
      } catch (_) {
        if (active()) {
          state = WeatherState(
            context: context,
            weather: state.weather,
            bridgeWarning: '天气已加载，但最近城市记录未同步，刷新可重试',
          );
        }
      }
    }
  }

  Future<void> close() async {
    try {
      await ref.read(hostBridgeProvider).close(state.context?.sessionId);
    } catch (_) {
      if (!_disposed) {
        state = WeatherState(
          context: state.context,
          weather: state.weather,
          error: '返回失败，请使用系统返回或重试',
        );
      }
    }
  }
}
