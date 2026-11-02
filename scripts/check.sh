#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$WEATHER_ROOT/weather_flutter"
flutter --no-version-check analyze
flutter --no-version-check test
cd "$WEATHER_ROOT/android-host"
./gradlew :core:model:test :core:data:testDebugUnitTest :feature:home:testDebugUnitTest :app:assembleDebug :app:lintDebug --console=plain
cd "$WEATHER_ROOT/ios-host/WeatherCore"
swift test
cd "$WEATHER_ROOT"
xcodebuild -project ios-host/WeatherHost.xcodeproj -scheme WeatherHost -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .tools/ios-build CODE_SIGNING_ALLOWED=NO build
