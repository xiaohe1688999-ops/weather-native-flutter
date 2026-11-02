import SwiftUI
import Flutter
import FlutterPluginRegistrant
import WeatherCore

struct FlutterWeatherView: UIViewControllerRepresentable {
    let city: City
    let onLoaded: () -> Void
    let onClose: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(city: city, onLoaded: onLoaded, onClose: onClose) }
    func makeUIViewController(context: Context) -> FlutterViewController { context.coordinator.start() }
    func updateUIViewController(_ controller: FlutterViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: FlutterViewController, coordinator: Coordinator) {
        coordinator.stop()
    }

    @MainActor
    final class Coordinator {
        private let city: City
        private let sessionID = UUID().uuidString
        private let onLoaded: () -> Void
        private let onClose: () -> Void
        private var engine: FlutterEngine?
        private var channel: FlutterMethodChannel?
        private var reported = false
        private var closed = false

        init(city: City, onLoaded: @escaping () -> Void, onClose: @escaping () -> Void) {
            self.city = city; self.onLoaded = onLoaded; self.onClose = onClose
        }

        func start() -> FlutterViewController {
            let engine = FlutterEngine(name: "weather-\(sessionID)")
            self.engine = engine
            // 引擎初始化与通道处理器注册在主线程同步完成。
            // Dart 的首次平台调用随后在同一线程处理。
            engine.run()
            GeneratedPluginRegistrant.register(with: engine)
            let channel = FlutterMethodChannel(name: "dev.weather/host", binaryMessenger: engine.binaryMessenger)
            self.channel = channel
            channel.setMethodCallHandler { [weak self] call, result in
                guard let self, !self.closed else {
                    result(FlutterError(code: "closed", message: "Session closed", details: nil)); return
                }
                let arguments = call.arguments as? [String: Any]
                switch call.method {
                case "getLaunchContext":
                    result(["protocolVersion": 1, "sessionId": self.sessionID, "location": self.city.channelMap])
                case "weatherLoaded":
                    guard arguments?["sessionId"] as? String == self.sessionID else {
                        result(FlutterError(code: "session", message: "Invalid session", details: nil)); return
                    }
                    if !self.reported { self.onLoaded(); self.reported = true }
                    result(nil)
                case "closeWeather":
                    let requested = arguments?["sessionId"] as? String
                    guard requested == nil || requested == self.sessionID else {
                        result(FlutterError(code: "session", message: "Invalid session", details: nil)); return
                    }
                    result(nil)
                    self.closed = true
                    self.onClose()
                default: result(FlutterMethodNotImplemented)
                }
            }
            return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        }

        func stop() {
            closed = true
            channel?.setMethodCallHandler(nil)
            channel = nil
            engine?.viewController = nil
            engine?.destroyContext()
            engine = nil
        }
    }
}
