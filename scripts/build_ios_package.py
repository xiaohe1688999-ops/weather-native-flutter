#!/usr/bin/env python3
"""Build with Flutter 3.47.3; isolate its cleared-environment xcrun workaround.

Never patches the installed SDK or changes global xcode-select. Remove the
workaround when an SDK upgrade fixes _produceXCFramework's environment handling.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parent.parent
sdk = Path(os.environ['FLUTTER_ROOT']).resolve()
mode = os.environ.get('FLUTTER_BUILD_MODE', 'debug')
arguments = ['--no-version-check', 'build', 'swift-package', '--platform', 'ios',
             '--build-mode', mode, '--no-codesign']
selection_env = dict(os.environ)
selection_env.pop('DEVELOPER_DIR', None)
selected = subprocess.check_output(['/usr/bin/xcode-select', '-p'], env=selection_env, text=True).strip()
developer = os.environ.get('DEVELOPER_DIR', selected)
if selected == developer:
    subprocess.run([str(sdk / 'bin/flutter')] + arguments, cwd=root / 'weather_flutter', check=True)
else:
    original = sdk / 'packages/flutter_tools'
    local = root / '.tools/flutter_tools'
    shutil.copytree(str(original), str(local), dirs_exist_ok=True)
    config_path = local / '.dart_tool/package_config.json'
    config = json.loads(config_path.read_text())
    for package in config['packages']:
        if package['name'] == 'flutter_tools':
            package['rootUri'] = '../'
    config_path.write_text(json.dumps(config))
    source = local / 'lib/src/commands/build_swift_package.dart'
    text = source.read_text()
    start = text.index('Future<void> _produceXCFramework(')
    prefix, body = text[:start], text[start:]
    before = 'includeParentEnvironment: false,'
    if before not in body:
        raise SystemExit('Flutter tool changed; review Xcode environment workaround before continuing.')
    source.write_text(prefix + body.replace(before, 'includeParentEnvironment: true,', 1))
    print('Using project-local Flutter tool copy to preserve DEVELOPER_DIR.', flush=True)
    subprocess.run([str(sdk / 'bin/cache/dart-sdk/bin/dart'),
                    '--packages=' + str(config_path), str(local / 'bin/flutter_tools.dart')] + arguments,
                   cwd=root / 'weather_flutter', check=True)
