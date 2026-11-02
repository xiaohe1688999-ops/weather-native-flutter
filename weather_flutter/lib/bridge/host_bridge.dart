import 'package:flutter/services.dart';

import '../domain/location.dart';

abstract interface class HostBridge {
  Future<LaunchContext> launchContext();
  Future<void> weatherLoaded(String sessionId);
  Future<void> close(String? sessionId);
}

class MethodChannelHostBridge implements HostBridge {
  const MethodChannelHostBridge();
  static const channel = MethodChannel('dev.weather/host');
  @override
  Future<LaunchContext> launchContext() async {
    final data = await channel.invokeMapMethod<Object?, Object?>(
      'getLaunchContext',
    );
    if (data == null) throw const FormatException('宿主未提供城市');
    return LaunchContext.fromMap(data);
  }

  @override
  Future<void> weatherLoaded(String sessionId) =>
      channel.invokeMethod<void>('weatherLoaded', {'sessionId': sessionId});
  @override
  Future<void> close(String? sessionId) =>
      channel.invokeMethod<void>('closeWeather', {'sessionId': sessionId});
}
