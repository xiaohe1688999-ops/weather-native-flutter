# 实施与验证记录

## 2026-11-02：GitHub 面试展示上传准备

- README 开头突出 Android / iOS 原生主页与 Flutter 共享天气详情页；保留现有功能、架构、截图和历史验证记录，未添加开源许可证。
- 忽略规则补充环境文件、签名与密钥资料及 APK / AAB / IPA；保留 Gradle Wrapper JAR、pubspec.lock、Flutter 模块元数据和 Xcode 共享 scheme。使用 `git check-ignore` 核对本机路径、缓存及临时工程均被排除。
- 清空 Xcode 工程中的个人 Development Team，运行者需自行选择 Team；本次模拟器构建不需要签名。
- 审查 65 个候选提交文件（含两张实际查看的天气截图）；关键词检查未发现个人绝对路径、凭据赋值或令牌格式，Gitleaks 8.30.1 暂存区扫描未发现密钥。保留应用原有开发者署名。此检查不构成第三方素材权属证明或无漏洞保证。
- `./scripts/prepare.sh`、`./scripts/check.sh` 本次均通过：Flutter 分析无问题、11 项测试通过；Android 5 项单元测试及 Debug 构建 / Lint 通过（0 错误、7 项既有警告）；Swift 4 项测试通过；iOS Debug 无签名模拟器构建通过。日志位于被忽略的 `.tools/github-prepare.log` 和 `.tools/github-check.log`。
- 额外检查通过：Markdown 本地链接、提交文件体积、必要构建文件、可执行权限、Shell / Ruby / Python 语法、plist 解析及 Xcode 工程格式。暂存差异按 Windows 批处理文件的 CRLF 行尾规则检查通过，未改写 Gradle Wrapper。
- 本次未重新运行在线 UI 冒烟、真机或 Release 签名验证。远程发布及克隆验收见下节。

### 公开发布与远程克隆验收

- 已发布至 [xiaohe1688999-ops/weather-native-flutter](https://github.com/xiaohe1688999-ops/weather-native-flutter)，可见性 Public，默认分支 main。首次提交 `df984de03be6a643650aed16bdc800259285297a`。
- 使用不带登录凭据的 HTTP 请求确认仓库首页及渲染的 README 可访问，两张预览截图、架构与验证文档均返回成功；远程 main 与本地提交一致。
- 使用禁用 Git credential helper 的 HTTPS 克隆取得源码，逐一比较 65 个文件与本地提交完全一致；必要脚本的可执行权限保留，本机配置和构建产物未进入源码树。
- 在新克隆目录执行 `./scripts/prepare.sh` 和 `./scripts/check.sh`，均以退出码 0 完成：Flutter 分析及 11 项测试、Android 5 项单元测试 / Debug 构建 / Lint（0 错误、7 项既有警告）、Swift 4 项测试、iOS Debug 无签名模拟器构建全部通过。克隆副本工作区干净。
- 此项验证使用同一台 macOS 的既有 SDK 和依赖缓存，未验证全新机器安装 SDK 的过程；日志为本地忽略文件 `.tools/github-remote-checkout/.tools/remote-prepare.log` 与 `remote-check.log`。
- QA 总评：上传清单、忽略规则、匿名访问与远程克隆构建验收通过；本次交付与 GitHub 面试展示上传方案一致。上述已声明的真机、在线 UI 重跑与 Release 验证不属于本次上传验收。

## 2026-11-02：IPA 生成尝试

- Flutter Release Swift Package 已生成成功，日志 `.tools/ipa-prepare.log`。
- 使用项目现有 Team、Automatic Signing、有效开发证书执行 Release Archive；先使用 generic iOS 目标，再指定已配对 iPad 并允许 Xcode 自动更新描述文件及登记设备，两次均失败于签名阶段。
- Xcode 实际错误：`Your team has no devices from which to generate a provisioning profile`；`No profiles for 'dev.weather.nativehost' were found`。日志 `.tools/ipa-archive.log` 保存最终尝试。
- 结果：未生成签名 Archive 或 IPA，未安装到真机，未发布。未更改项目 Team、Bundle ID 或签名配置。需先在当前开发者 Team 中完成设备登记并取得匹配的开发描述文件，再重试归档和 debugging 导出。

## 2026-11-02：首页开发者署名

- 要求与实现：Android / iOS 首页均按“天气手记 → 开发者：何送军 → 从一座城市，了解今天。”展示；署名与介绍使用相同次要文字颜色和默认常规字号。仅增加展示文本及 Android 行间距，不改动业务逻辑。
- 构建：`:app:assembleDebug` 通过（`.tools/signature-android-build.log`）；iOS Debug 模拟器 `xcodebuild ... build` 通过（`.tools/signature-ios-build.log`）。
- QA：脚本核对两端源码的三行顺序通过；已查看 Android 320×480 模拟器截图，署名完整、顺序正确、搜索框与最近列表无重叠（`.tools/signature-android.png`）。iOS 页面目视验收未执行：模拟器安装命令持续未返回，已停止本次安装检查；构建通过不能替代页面验收。
- 一致性：实现与方案一致，验收部分一致；剩余项为 iOS 页面目视检查。此文案改动未新增单元测试。

日期：2026-11-01。本文是基于源码、测试报告和模拟器操作的结构化自检，并非第三方 QA。

## 目标与验收映射

实施范围：Android Compose 与 iOS SwiftUI 原生城市搜索页，共享 Flutter 当前天气 / 7 天预报页；通过平台通道传参、返回、记录最近城市。额外目标是让 Android 开发者学习双宿主嵌入 Flutter，而非严格控制在题目原定的 4–6 小时。

| 要求 | 实施与验收标准 | 实际证据与结果 |
| --- | --- | --- |
| 搜索地点 | 原生输入、防抖、同名地点区分；选中后进入详情 | 两端在线搜索上海、进入天气、返回、最近城市及再次进入测试通过；空结果与非法坐标有模型解析测试 |
| 当前天气和预报 | Flutter 展示真实数据、当地时间、7 天高低温及降水概率 | Open-Meteo 接口实测成功；两端模拟器均已观察到真实天气页；Flutter 解析与布局测试通过 |
| Loading / Error | 搜索、首屏和刷新状态；失败重试；刷新失败保留已有天气 | 源码检查；Android ViewModel 错误恢复测试、Flutter 首屏重试及刷新失败测试通过；真机断网交互未执行 |
| 架构和组件 | 网络、模型、状态、UI、宿主桥接分离 | 检查 Android 三个库模块、Swift WeatherCore 包及 Flutter 分层目录；实现与架构文档一致 |
| 状态管理 | 取消过期请求、抑制旧响应、最近城市去重最多 5 条 | Flutter 竞态 / 取消测试、Android 防抖测试、Swift 旧搜索响应抑制测试和最近列表测试通过 |
| 原生 + Flutter | 城市参数协议、首次成功回调、返回、独立引擎释放 | Dart MethodChannel 协议测试通过；两端在线往返和重复进入通过；两端宿主移除 handler / 销毁引擎的源码已检查；未做内存泄漏仪器检测 |
| 可维护性与交付 | 可运行源码、锁定依赖、README、运行和测试入口 | 源码、Gradle Wrapper、pubspec.lock、共享 Xcode scheme 和脚本已交付；脚本语法和 plist 校验通过 |

## 实际执行

以下命令由项目根目录执行，需先具备 README 中的 SDK 环境。构建产物和本机日志位于被忽略的 `.tools/` / `build/`，不属于源码交付依赖。

| 检查 | 命令 / 方法 | 结果 |
| --- | --- | --- |
| 环境准备 | `./scripts/prepare.sh` | 通过；生成 Flutter 临时工程、iOS Swift Package、本机路径 |
| Flutter 静态检查 | `cd weather_flutter && flutter --no-version-check analyze` | 通过，无问题；`.tools/flutter-analyze.log` |
| Flutter 测试 | `cd weather_flutter && flutter --no-version-check test` | 11 项通过；协议、解析、状态、竞态、取消、重试、手机 / 平板及 320 宽度双倍字体布局；`.tools/flutter-test.log` |
| Android 单元测试 | `cd android-host && ./gradlew :core:model:test :core:data:testDebugUnitTest :feature:home:testDebugUnitTest` | 5 项通过；各模块 `build/test-results/` |
| Android Debug 构建 / Lint | `cd android-host && ./gradlew :app:assembleDebug :app:lintDebug` | 最终代码通过；Lint 0 错误、7 警告（版本更新提示、备份规则、应用图标）；`.tools/android-final.log` |
| Android 在线 UI | `./scripts/smoke-android.sh` | 最终代码 1 项完整流程通过；Android 10 / API 29 小屏模拟器，搜索上海、滚动查看 Flutter 预报、横竖屏、返回、最近城市、再次进入；`.tools/android-smoke.log` |
| Swift 核心层 | `cd ios-host/WeatherCore && swift test` | 4 项通过；`.tools/swift-test.log`；macOS 运行，不等于 iOS UI 测试 |
| iOS Debug 构建 | README 的 `xcodebuild ... build` | 通过；无签名模拟器构建 |
| iOS 在线 UI | `IOS_SIMULATOR_ID=... ./scripts/smoke-ios.sh` | 最终代码 1 项完整流程通过；iPhone 17 Pro / iOS 26.3 模拟器，含重启后的最近列表和天气截图；`.tools/ios-smoke.log`，结果包 `Test-WeatherHost-2026.11.01_22-12-27-+0800.xcresult` |
| 脚本 / 配置 | `bash -n scripts/*.sh`（逐文件）、`ruby -c scripts/create_ios_project.rb`、Python AST、`plutil -lint` 两份 plist | 通过；仅语法 / 格式验证，不等于全部分支运行 |

## 发现的问题与改进

1. Android 的新版 Compose 依赖要求比当前 SDK 更高，Flutter 插件仍引用 AGP 旧 DSL。固定兼容 SDK 36 的 BOM 并显式设置 `android.newDsl=false`，构建已通过。此兼容开关有弃用警告，升级 AGP 前必须复核。
2. 全局 Xcode 路径为 Command Line Tools，Flutter 创建 XCFramework 的子进程清空环境。准备脚本仅在项目内复制工具并保留 `DEVELOPER_DIR`；没有改动系统选择或安装的 Flutter SDK。已实际生成 Swift Package。此处理与 Flutter 版本耦合，升级需检查。
3. 手动安装 FlutterSceneDelegate 覆盖 SwiftUI 场景管理，导致 iOS 首页白屏。移除该配置，由 SwiftUI 创建窗口；修订后已观察到原生搜索及 Flutter 天气。根因是将 UIKit 场景配置套用于 SwiftUI 宿主；后续插件加入时须按实际生命周期需求集成。
4. 原生键盘可能遮挡重复进入时的页面；两端选城前主动取消输入焦点。Android 完整往返测试通过。
5. Flutter 无障碍树中的文本类型与原生控件不同，早期测试使用原生文本定位导致误报。Android 改查 accessibility description，iOS 使用 Flutter Semantics identifier；iOS 修订后完整测试通过。Android 小屏预报在首屏下方，测试需滚动查找，而非假设所有数据首屏可见。
6. iOS 缺少部分 Unicode 天气符号字形。改用随包携带的 Material 图标，避免依赖设备字体；Flutter 布局测试通过，两端最终截图确认图标正常。

最终截图：[Android](images/android-weather.png)、[iOS](images/ios-weather.png)。iOS 截图来自最终 XCTest 的 keepAlways 附件，已实际导出并查看；Android 截图来自最终安装包运行页面。截图是当时的在线数据，不是测试固定预期。

已保留的合理取舍：天气逻辑由 Flutter 共享；原生状态与网络分别实现，便于对比学习；只用三个 MethodChannel 方法和手动依赖组装；每次进入独立引擎便于追踪所有权。未引入定位、登录、数据库、服务端和引擎缓存。

## 未执行与剩余风险

- 实体 Android / iPhone、iOS 签名和 Release / 商店构建：未执行。
- 系统回收后恢复、低内存、完整前后台矩阵、不同系统版本和长期内存稳定性：未执行；Android 参数恢复仅完成源码检查，旋转已实际测试。
- 网络中断 / 限流 / 超时的两端原生界面操作：未执行；自动化覆盖部分状态逻辑，不能替代真实设备断网验证。
- 在线测试依赖公共 API，不能保证未来始终可用；不提供生产 SLA。该项目尚未验证商业发布条件。
- iOS / Android 平板真机与屏幕阅读器操作：未执行；Flutter 仅完成不同宽度及大字体组件测试。

## QA 总评与一致性

源码功能与选定架构已完成，两端完整在线链路均有通过记录。功能实现与选定方案**一致**；完整验收**部分一致**，尚未执行上述真机、进程回收和发布相关项目。当前自动化结果不替代这些验收。下一阶段聚焦真机生命周期与资源释放验证。
