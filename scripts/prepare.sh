#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$WEATHER_ROOT/weather_flutter"
flutter --no-version-check pub get
python3 "$WEATHER_ROOT/scripts/build_ios_package.py"
cd "$WEATHER_ROOT"
python3 - <<'PY'
import os
from pathlib import Path
def escape(s): return s.replace('\\', '\\\\').replace(':', '\\:').replace('=', '\\=')
Path('android-host/local.properties').write_text(
    'sdk.dir=' + escape(os.environ['ANDROID_HOME']) + '\nflutter.sdk=' + escape(os.environ['FLUTTER_ROOT']) + '\n')
PY
echo 'Prepared. Open android-host/ in Android Studio, or ios-host/WeatherHost.xcodeproj in Xcode.'
