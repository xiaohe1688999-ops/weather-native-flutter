#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$WEATHER_ROOT"
: "${IOS_SIMULATOR_ID:?Set IOS_SIMULATOR_ID from xcrun simctl list devices available}"
xcodebuild -project ios-host/WeatherHost.xcodeproj -scheme WeatherHost -configuration Debug \
  -destination "platform=iOS Simulator,id=$IOS_SIMULATOR_ID" \
  -parallel-testing-enabled NO \
  -derivedDataPath .tools/ios-build CODE_SIGNING_ALLOWED=NO test
