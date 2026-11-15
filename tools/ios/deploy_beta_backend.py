"""Provision an isolated TestFlight economy using the existing Cloudflare account."""
import json
import os
from pathlib import Path
import subprocess
import time
import tomllib
import urllib.request


def api(path, body=None):
    account = os.environ['CLOUDFLARE_ACCOUNT_ID']
    request = urllib.request.Request(
        f'https://api.cloudflare.com/client/v4/accounts/{account}/{path}',
        data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization': f"Bearer {os.environ['CLOUDFLARE_API_TOKEN']}",
                 'Content-Type': 'application/json'},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = json.load(response)
    if not payload.get('success'):
        raise RuntimeError(f'Cloudflare could not configure {path}')
    return payload['result']


def main():
    name = 'ludo-cheer-ios-beta'
    databases = api('d1/database?per_page=100')
    database = next((db for db in databases if db['name'] == name), None)
    if database is None:
        database = api('d1/database', {'name': name, 'primary_location_hint': 'enam'})
    queues = api('queues?per_page=100')
    if not any(queue['queue_name'] == name for queue in queues):
        api('queues', {'queue_name': name})
    original = tomllib.loads(Path('wrangler.toml').read_text())
    config = {
        'name': name, 'main': 'src/index.ts',
        'compatibility_date': original['compatibility_date'],
        'compatibility_flags': original['compatibility_flags'],
        'vars': {'APP_STORE_ENVIRONMENT': 'Sandbox', 'FORCE_LATEST_ANDROID_BUILD': 'false'},
        'durable_objects': original['durable_objects'], 'migrations': original['migrations'],
        'd1_databases': [{'binding': 'DB', 'database_name': name, 'database_id': database['uuid']}],
        'services': [{'binding': 'VOICE_RELAY', 'service': original['name'], 'entrypoint': 'VoiceRelay'}],
        'queues': {'producers': [{'binding': 'BACKGROUND_QUEUE', 'queue': name}],
                   'consumers': [{'queue': name, 'max_batch_size': 10, 'max_batch_timeout': 30}]},
    }
    path = Path('wrangler.ios-beta.json')
    path.write_text(json.dumps(config, indent=2))
    command = ['npx', 'wrangler']
    subprocess.run([*command, 'd1', 'migrations', 'apply', name, '--remote', '--config', str(path)], check=True)
    # The production backend deploy runs independently on main. Allow its named
    # RPC entrypoint to become available without copying the production TURN key.
    for attempt in range(4):
        deployment = subprocess.run([*command, 'deploy', '--config', str(path)])
        if deployment.returncode == 0:
            break
        if attempt == 3:
            deployment.check_returncode()
        time.sleep(15)
    subdomain = api('workers/subdomain')['subdomain']
    url = f'https://{name}.{subdomain}.workers.dev'
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        output.write(f'backend_url={url}\n')
    print('Configured an isolated TestFlight backend; sandbox purchases cannot credit production wallets.')


if __name__ == '__main__':
    main()
