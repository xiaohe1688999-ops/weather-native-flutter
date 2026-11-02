#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$WEATHER_ROOT/android-host"
./gradlew :app:connectedDebugAndroidTest --console=plain
