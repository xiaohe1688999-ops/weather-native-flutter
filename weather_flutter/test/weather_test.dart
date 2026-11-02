import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_flutter/bridge/host_bridge.dart';
import 'package:weather_flutter/data/weather_repository.dart';
import 'package:weather_flutter/domain/location.dart';
import 'package:weather_flutter/domain/weather.dart';
import 'package:weather_flutter/main.dart';
import 'package:weather_flutter/state/weather_controller.dart';

const city = Location(
  id: 1796236,
  name: '上海',
  latitude: 31.22,
  longitude: 121.45,
  country: '中国',
);
const launch = LaunchContext(sessionId: 'test-session', location: city);
Weather sample([double temperature = 20]) => Weather(
  current: CurrentWeather(
    temperature: temperature,
    code: 0,
    localTime: '2026-11-01T09:00',
  ),
  days: List.generate(
    7,
    (i) => ForecastDay(
      date: '2026-11-0${i + 1}',
      code: 3,
      high: 23,
      low: 15,
      rain: 10,
    ),
  ),
  timezone: 'Asia/Shanghai',
);

class FakeBridge implements HostBridge {
  int reports = 0, closes = 0;
  bool brokenContext = false, brokenReport = false;
  @override
  Future<LaunchContext> launchContext() async {
    if (brokenContext) throw const FormatException();
    return launch;
  }

  @override
  Future<void> weatherLoaded(String sessionId) async {
    if (brokenReport) throw PlatformException(code: 'storage');
    reports++;
  }

  @override
  Future<void> close(String? sessionId) async {
    closes++;
  }
}

class FakeRepository implements WeatherRepository {
  final requests = <Completer<Weather>>[];
  final tokens = <CancelToken>[];
  @override
  Future<Weather> fetch(Location location, CancelToken token) {
    tokens.add(token);
    final request = Completer<Weather>();
    requests.add(request);
    return request.future;
  }
}

Future<void> flush() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('launch contract validates version and coordinates', () {
    expect(
      () => LaunchContext.fromMap({'protocolVersion': 9}),
      throwsFormatException,
    );
    expect(
      () => Location.fromMap({
        'id': 1,
        'name': 'X',
        'latitude': 91,
        'longitude': 0,
      }),
      throwsFormatException,
    );
    expect(
      LaunchContext.fromMap({
        'protocolVersion': 1,
        'sessionId': 'a',
        'location': {'id': 1, 'name': '上海', 'latitude': 31, 'longitude': 121},
      }).location.name,
      '上海',
    );
  });
  test('parser accepts missing metrics and shorter metric arrays', () {
    final weather = Weather.fromJson({
      'current': {},
      'daily': {
        'time': ['2026-11-01', '2026-11-02'],
        'temperature_2m_max': [22],
      },
      'timezone': 'Asia/Shanghai',
    });
    expect(weather.current.temperature, isNull);
    expect(weather.days[1].high, isNull);
    expect(weatherDescription(999), '天气未知');
    expect(
      () => Weather.fromJson({
        'current': {},
        'daily': {
          'time': ['bad'],
        },
      }),
      throwsFormatException,
    );
    expect(() => Weather.fromJson({}), throwsFormatException);
  });
  test('method channel implements the agreed wire contract', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelHostBridge.channel, (
          call,
        ) async {
          calls.add(call);
          if (call.method == 'getLaunchContext') {
            return {
              'protocolVersion': 1,
              'sessionId': 's',
              'location': {
                'id': 1,
                'name': '上海',
                'latitude': 31.0,
                'longitude': 121.0,
              },
            };
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannelHostBridge.channel, null),
    );
    const bridge = MethodChannelHostBridge();
    expect((await bridge.launchContext()).sessionId, 's');
    await bridge.weatherLoaded('s');
    await bridge.close('s');
    expect(calls.map((c) => c.method), [
      'getLaunchContext',
      'weatherLoaded',
      'closeWeather',
    ]);
    expect(calls[1].arguments, {'sessionId': 's'});
  });

  late ProviderContainer container;
  late FakeRepository repository;
  late FakeBridge bridge;
  setUp(() {
    repository = FakeRepository();
    bridge = FakeBridge();
    container = ProviderContainer(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(repository),
        hostBridgeProvider.overrideWithValue(bridge),
      ],
    );
  });
  tearDown(() => container.dispose());
  test(
    'successful load reports once and refresh failure retains old data',
    () async {
      final controller = container.read(weatherControllerProvider.notifier);
      final first = controller.load();
      await flush();
      expect(container.read(weatherControllerProvider).loading, isTrue);
      repository.requests[0].complete(sample());
      await first;
      expect(bridge.reports, 1);
      final refresh = controller.load();
      await flush();
      repository.requests[1].completeError(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      await refresh;
      expect(
        container.read(weatherControllerProvider).weather!.current.temperature,
        20,
      );
      expect(container.read(weatherControllerProvider).error, contains('超时'));
      final retry = controller.load();
      await flush();
      repository.requests[2].complete(sample(21));
      await retry;
      expect(container.read(weatherControllerProvider).error, isNull);
      expect(bridge.reports, 1);
    },
  );
  test('older response cannot overwrite newer weather', () async {
    final controller = container.read(weatherControllerProvider.notifier);
    final older = controller.load();
    await flush();
    final newer = controller.load();
    await flush();
    expect(repository.tokens[0].isCancelled, isTrue);
    repository.requests[1].complete(sample(25));
    await newer;
    repository.requests[0].complete(sample(10));
    await older;
    expect(
      container.read(weatherControllerProvider).weather!.current.temperature,
      25,
    );
  });
  test(
    'invalid host context produces recoverable error and no API call',
    () async {
      bridge.brokenContext = true;
      await container.read(weatherControllerProvider.notifier).load();
      expect(repository.requests, isEmpty);
      expect(container.read(weatherControllerProvider).error, contains('城市参数'));
      await container.read(weatherControllerProvider.notifier).close();
      expect(bridge.closes, 1);
    },
  );
  test(
    'bridge failure preserves weather and retries record on refresh',
    () async {
      bridge.brokenReport = true;
      final first = container.read(weatherControllerProvider.notifier).load();
      await flush();
      repository.requests[0].complete(sample());
      await first;
      expect(container.read(weatherControllerProvider).weather, isNotNull);
      expect(
        container.read(weatherControllerProvider).bridgeWarning,
        isNotNull,
      );
      bridge.brokenReport = false;
      final retry = container.read(weatherControllerProvider.notifier).load();
      await flush();
      repository.requests[1].complete(sample());
      await retry;
      expect(bridge.reports, 1);
      expect(container.read(weatherControllerProvider).bridgeWarning, isNull);
    },
  );
  test('disposing provider cancels the active network request', () async {
    final operation = container.read(weatherControllerProvider.notifier).load();
    await flush();
    container.invalidate(weatherControllerProvider);
    expect(repository.tokens.single.isCancelled, isTrue);
    repository.requests.single.complete(sample());
    await operation;
  });
  testWidgets('mobile and tablet show weather and return to host', (
    tester,
  ) async {
    for (final size in [const Size(390, 844), const Size(1024, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherRepositoryProvider.overrideWithValue(repository),
            hostBridgeProvider.overrideWithValue(bridge),
          ],
          child: const WeatherApp(),
        ),
      );
      await tester.pump();
      expect(find.text('正在获取天气…'), findsOneWidget);
      repository.requests.last.complete(sample());
      await tester.pumpAndSettle();
      expect(find.text('上海'), findsOneWidget);
      expect(find.text('未来 7 天'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('返回城市搜索'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    }
    expect(bridge.closes, 2);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('initial failure shows retry action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(repository),
          hostBridgeProvider.overrideWithValue(bridge),
        ],
        child: const WeatherApp(),
      ),
    );
    await tester.pump();
    repository.requests.single.completeError(const FormatException());
    await tester.pumpAndSettle();
    expect(find.text('天气数据格式异常，请重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(repository.requests.length, 2);
    repository.requests.last.complete(sample());
    await tester.pumpAndSettle();
    expect(find.text('上海'), findsOneWidget);
  });
  testWidgets('narrow layout supports large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(repository),
          hostBridgeProvider.overrideWithValue(bridge),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const WeatherApp(),
        ),
      ),
    );
    await tester.pump();
    repository.requests.single.complete(sample());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
