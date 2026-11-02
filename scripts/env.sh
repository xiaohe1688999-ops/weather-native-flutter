#!/usr/bin/env bash
# 由项目脚本加载；始终优先采用用户显式设置的环境变量。
WEATHER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${FLUTTER_ROOT:-}" ]]; then
  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_ROOT="$(cd "$(dirname "$(command -v flutter)")/.." && pwd)"
  elif [[ -x "$HOME/Library/Caches/flutter-learning-sdk/flutter/bin/flutter" ]]; then
    FLUTTER_ROOT="$HOME/Library/Caches/flutter-learning-sdk/flutter"
  else
    echo 'Set FLUTTER_ROOT to Flutter 3.47.3 SDK.' >&2
    return 1
  fi
fi
export FLUTTER_ROOT
export PATH="$FLUTTER_ROOT/bin:$PATH"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if [[ -z "${JAVA_HOME:-}" ]] || ! "$JAVA_HOME/bin/java" -version 2>&1 | head -1 | /usr/bin/grep -Eq '"17[.]'; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
fi
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
