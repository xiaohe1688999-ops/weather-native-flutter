import SwiftUI
import Flutter

// 场景与窗口由 SwiftUI 管理；替换其场景代理会导致
// WindowGroup 无法挂载原生主页。
final class AppDelegate: FlutterAppDelegate {}

@main
struct WeatherHostApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { WindowGroup { HomeView() } }
}
