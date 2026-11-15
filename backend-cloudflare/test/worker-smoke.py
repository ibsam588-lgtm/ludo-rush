"""Exercise the real Workers runtime, including Apple's request-time verifier."""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import urllib.error
import urllib.request


def main():
    npx = shutil.which('npx')
    if not npx:
        raise RuntimeError('Node.js/npm is required')
    with tempfile.TemporaryDirectory(prefix='ludo-worker-smoke-') as temporary:
        command = [npx, 'wrangler']
        subprocess.run([*command, 'd1', 'migrations', 'apply', 'ludo-rush-db',
                        '--local', '--persist-to', temporary], check=True)
        log_path = Path(temporary) / 'worker.log'
        with log_path.open('w', encoding='utf-8') as log:
            process = subprocess.Popen(
                [*command, 'dev', '--local', '--ip', '127.0.0.1', '--port', '8799',
                 '--persist-to', temporary, '--show-interactive-dev-session=false'],
                stdout=log, stderr=subprocess.STDOUT,
                env={**os.environ, 'WRANGLER_SEND_METRICS': 'false'},
                start_new_session=os.name != 'nt',
            )
            try:
                base = 'http://127.0.0.1:8799'
                for attempt in range(60):
                    if process.poll() is not None:
                        raise RuntimeError(log_path.read_text(encoding='utf-8'))
                    try:
                        with urllib.request.urlopen(base + '/health', timeout=1) as response:
                            assert json.load(response)['ok'] is True
                        break
                    except (urllib.error.URLError, TimeoutError):
                        if attempt == 59:
                            raise RuntimeError(log_path.read_text(encoding='utf-8'))
                        time.sleep(0.5)
                request = urllib.request.Request(base + '/api/v1/auth/guest',
                    data=json.dumps({'displayName': 'Runtime smoke', 'age': 25}).encode(),
                    headers={'Content-Type': 'application/json'})
                with urllib.request.urlopen(request, timeout=5) as response:
                    guest = json.load(response)
                    assert response.status == 201
                request = urllib.request.Request(base + '/api/v1/auth/session',
                    headers={'Authorization': 'Bearer ' + guest['token']})
                with urllib.request.urlopen(request, timeout=5) as response:
                    assert json.load(response)['playerId'] == guest['player']['id']
                    assert response.headers['cache-control'] == 'no-store'
                try:
                    urllib.request.urlopen(base + '/api/v1/auth/session', timeout=5)
                    raise AssertionError('An unauthenticated checkout session was accepted')
                except urllib.error.HTTPError as error:
                    assert error.code == 401
                # Pass the JWS shape guard so the official Apple verifier really
                # loads inside workerd. Forged data must never award purchases.
                request = urllib.request.Request(base + '/api/v1/purchases/app-store/verify',
                    data=json.dumps({'productId': 'coins.stack_1200',
                                     'signedTransaction': 'a' * 80 + '.' + 'b' * 80 + '.c'}).encode(),
                    headers={'Content-Type': 'application/json',
                             'Authorization': 'Bearer ' + guest['token']})
                try:
                    urllib.request.urlopen(request, timeout=10)
                    raise AssertionError('A forged App Store transaction was accepted')
                except urllib.error.HTTPError as error:
                    assert error.code == 400, error.read().decode()
                    assert 'Apple could not verify' in json.load(error)['error']
                request = urllib.request.Request(base + '/api/v1/auth/app-store',
                    data=json.dumps({'signedAppTransaction': 'a' * 80 + '.' + 'b' * 80 + '.c'}).encode(),
                    headers={'Content-Type': 'application/json',
                             'Authorization': 'Bearer ' + guest['token']})
                try:
                    urllib.request.urlopen(request, timeout=10)
                    raise AssertionError('A forged App Store account proof was accepted')
                except urllib.error.HTTPError as error:
                    assert error.code == 400, error.read().decode()
                    assert 'Apple could not verify' in json.load(error)['error']
                print('Workers runtime: healthy launch, authenticated checkout, forged Apple purchases and account proofs rejected.')
            finally:
                if os.name == 'nt':
                    subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
                else:
                    os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)


if __name__ == '__main__':
    main()
