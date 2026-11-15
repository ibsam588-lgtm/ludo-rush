"""Capture actual native iPhone/iPad UI, never stretch phone images into iPad images."""
import json
import os
from pathlib import Path
import signal
import subprocess


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def main():
    devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '-j', capture_output=True).stdout)['devices']
    available = [device for runtime in reversed(list(devices.values())) for device in runtime]
    groups = {
        'iphone-6.9': ['iPhone 17 Pro Max', 'iPhone 16 Pro Max', 'iPhone 16 Plus'],
        'ipad-13': ['iPad Pro 13-inch (M5)', 'iPad Pro 13-inch (M4)', 'iPad Air 13-inch (M3)', 'iPad Air 13-inch (M2)'],
    }
    output = Path('build/ios-store').resolve()
    output.mkdir(parents=True, exist_ok=True)
    evidence = []
    for group, names in groups.items():
        device = next((d for name in names for d in available if d['name'] == name), None)
        if device is None:
            raise RuntimeError(f'No supported {group} simulator; available: {[d["name"] for d in available]}')
        udid = device['udid']
        subprocess.run(['xcrun', 'simctl', 'boot', udid], check=False)
        run('xcrun', 'simctl', 'bootstatus', udid, '-b')
        run('xcrun', 'simctl', 'status_bar', udid, 'override', '--time', '9:41',
            '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'charged', '--batteryLevel', '100')
        folder = output / group
        folder.mkdir(exist_ok=True)
        # The first run includes iPhone gameplay; retain the full native recording
        # for an App Preview edit, rather than manufacturing motion from stills.
        recording = subprocess.Popen(['xcrun', 'simctl', 'io', udid, 'recordVideo',
                                     '--codec=h264', '--force', str(folder / 'native-gameplay.mov')])
        try:
            run('flutter', 'drive', '-d', udid,
                '--driver=ios/store_assets/driver.dart', '--target=ios/store_assets/capture_test.dart',
                '--dart-define=LEVELPLAY_PRODUCTION=true',
                env={**os.environ, 'IOS_SCREENSHOT_DIR': str(folder)})
        finally:
            recording.send_signal(signal.SIGINT)
            recording.wait(timeout=30)
        screenshots = sorted(folder.glob('*.png'))
        if len(screenshots) != 5:
            raise RuntimeError(f'Expected five real screenshots for {group}, received {len(screenshots)}')
        evidence.append({'format': group, 'device': device['name'], 'screenshots': [p.name for p in screenshots]})
        run('xcrun', 'simctl', 'shutdown', udid)
    (output / 'capture-manifest.json').write_text(json.dumps(evidence, indent=2))


if __name__ == '__main__':
    main()
