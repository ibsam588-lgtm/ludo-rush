"""App Store Connect API client for repeatable Ludo Cheer store setup.

Requires PyJWT and cryptography. Supply ASC_KEY_ID, ASC_ISSUER_ID and
ASC_KEY_PATH in the local environment; credentials are never written or logged.
"""
import json
import os
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt


class AppleAPIError(RuntimeError):
    def __init__(self, status, payload):
        self.status = status
        self.payload = payload
        errors = payload.get('errors', [])
        super().__init__('Apple API ' + str(status) + ': ' + '; '.join(
            str(error.get('code', '')) + ' ' + str(error.get('detail', ''))
            for error in errors))


class AppStoreClient:
    base = 'https://api.appstoreconnect.apple.com'

    def __init__(self):
        self.key_id = os.environ['ASC_KEY_ID']
        self.issuer = os.environ['ASC_ISSUER_ID']
        self.key = Path(os.environ['ASC_KEY_PATH']).read_bytes()

    def request(self, method, path, body=None):
        url = path if path.startswith(self.base + '/') else self.base + path
        if urllib.parse.urlsplit(url).netloc != 'api.appstoreconnect.apple.com':
            raise ValueError('Refusing to send Apple credentials to another host')
        now = int(time.time())
        token = jwt.encode({'iss': self.issuer, 'iat': now, 'exp': now + 600,
                            'aud': 'appstoreconnect-v1'}, self.key, algorithm='ES256',
                           headers={'kid': self.key_id, 'typ': 'JWT'})
        request = urllib.request.Request(url, method=method,
            data=json.dumps(body).encode() if body is not None else None,
            headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                data = response.read()
                return json.loads(data) if data else {}
        except urllib.error.HTTPError as error:
            try:
                payload = json.loads(error.read())
            except ValueError:
                payload = {'errors': [{'code': 'HTTP_ERROR', 'detail': 'Apple returned a non-JSON error'}]}
            raise AppleAPIError(error.code, payload) from None

    def all(self, path):
        rows = []
        while path:
            response = self.request('GET', path)
            rows.extend(response['data'])
            path = response.get('links', {}).get('next')
        return rows
