"""Upload reviewed native media using Apple's current asset-library API.

Requires Pillow and the environment documented in app_store_api.py. This only edits the
draft listing and purchase-review metadata; it never submits an App Store review.
Existing placements are retained. Re-running reuses content-addressed images.
"""
import argparse
import hashlib
import json
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

from app_store_api import AppStoreClient, AppleAPIError


APP_ID = '6834993861'
GROUPS = {'iphone-6.9': 'IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE',
          'ipad-13': 'IPAD_13_PROFILE'}


def opaque_image(path):
    """Remove an unused alpha channel without changing native screenshot pixels."""
    from PIL import Image
    with Image.open(path) as image:
        if image.mode == 'RGB':
            return path
        rgba = image.convert('RGBA')
        if rgba.getchannel('A').getextrema() != (255, 255):
            raise ValueError(f'The native screenshot has transparent pixels: {path.name}')
        target = path.parent / 'apple-opaque' / path.name
        target.parent.mkdir(exist_ok=True)
        rgba.convert('RGB').save(target, format='PNG', optimize=True,
                                 icc_profile=image.info.get('icc_profile'))
        return target


def relation(kind, identifier):
    return {'data': {'type': kind, 'id': identifier}}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def upload_parts(path, operations):
    """Send only the declared bytes and headers to Apple's temporary storage."""
    size = path.stat().st_size
    ranges = sorted((op['offset'], op['offset'] + op['length']) for op in operations)
    cursor = 0
    for start, end in ranges:
        if start != cursor or end <= start or end > size:
            raise ValueError('Apple upload ranges overlap, leave missing bytes or exceed the file')
        cursor = end
    if cursor != size:
        raise ValueError('Apple upload operations do not cover the complete file')
    opener = urllib.request.build_opener(NoRedirect)
    with path.open('rb') as source:
        for operation in operations:
            url = urllib.parse.urlsplit(operation['url'])
            if (url.scheme != 'https' or not url.hostname or
                    not url.hostname.endswith('.apple.com') or url.username or url.password):
                raise ValueError('Refusing an upload destination outside Apple HTTPS storage')
            offset, length = operation['offset'], operation['length']
            if offset < 0 or length <= 0 or offset + length > size:
                raise ValueError('Invalid Apple upload byte range')
            source.seek(offset)
            body = source.read(length)
            headers = {header['name']: header['value'] for header in operation['requestHeaders']}
            if any(name.lower() == 'authorization' for name in headers):
                raise ValueError('Asset transfers must not include authentication headers')
            request = urllib.request.Request(operation['url'], data=body,
                                             method=operation['method'], headers=headers)
            try:
                with opener.open(request, timeout=120) as response:
                    if not 200 <= response.status < 300:
                        raise RuntimeError(f'Apple asset transfer failed: HTTP {response.status}')
            except urllib.error.HTTPError as error:
                raise RuntimeError(f'Apple asset transfer failed: HTTP {error.code}') from None
            except urllib.error.URLError:
                raise RuntimeError('Apple asset transfer failed: network error') from None


def wait_ready(api, endpoint, identifier, review=False):
    for _ in range(120):
        data = api.request('GET', f'{endpoint}/{identifier}')['data']
        attributes = data['attributes']
        state = (attributes.get('assetDeliveryState') or {}).get('state') if review else attributes['state']
        if state in ('PREPARE_FOR_SUBMISSION', 'APPROVED', 'COMPLETE'):
            return data
        if state in ('FAILED', 'UPLOAD_FAILED'):
            raise RuntimeError(f'Apple could not process {identifier}: {attributes.get("stateDetails") or attributes.get("assetDeliveryState")}')
        time.sleep(5)
    raise RuntimeError(f'Apple is still processing {identifier}; re-run after processing finishes')


def library_asset(api, library, path, video=False):
    endpoint = '/v1/appAssetLibraryVideos' if video else '/v1/appAssetLibraryImages'
    kind = endpoint.split('/')[-1]
    digest = hashlib.sha256(path.read_bytes()).hexdigest()[:20]
    reference = f'Ludo Cheer {path.parent.name} {path.stem} {digest}'
    query = urllib.parse.urlencode({'filter[referenceName]': reference, 'limit': 200})
    existing = api.all(f'/v1/appAssetLibraries/{library}/{"videos" if video else "images"}?{query}')
    asset = next((row for row in existing if row['attributes']['state'] not in ('FAILED', 'ARCHIVED')), None)
    if asset is None:
        attributes = {'fileName': path.name, 'fileSize': path.stat().st_size,
                      'category': 'APP_SCREENSHOTS_AND_PREVIEWS', 'referenceName': reference}
        if video:
            attributes['previewFrameTimeCode'] = '00:00:03:00'
        asset = api.request('POST', endpoint, {'data': {
            'type': kind, 'attributes': attributes,
            'relationships': {'assetLibrary': relation('appAssetLibraries', library)},
        }})['data']
    if asset['attributes']['state'] == 'AWAITING_UPLOAD':
        upload_parts(path, asset['attributes']['uploadOperations'])
        api.request('PATCH', f'{endpoint}/{asset["id"]}', {'data': {
            'type': kind, 'id': asset['id'], 'attributes': {'uploaded': True},
        }})
    ready = wait_ready(api, endpoint, asset['id'])
    print('Processed', path.name, ready['id'], flush=True)
    return ready


def place(api, asset, localization, group, video=False):
    media = 'video' if video else 'image'
    query = urllib.parse.urlencode({'filter[placementGroup]': group, 'include': media, 'limit': 200})
    placements = api.all(f'/v1/appStoreVersionLocalizations/{localization}/placements?{query}')
    for row in placements:
        linked = row.get('relationships', {}).get(media, {}).get('data')
        if linked and linked['id'] == asset['id']:
            return row
    return api.request('POST', '/v1/appAssetLibraryPlacements', {'data': {
        'type': 'appAssetLibraryPlacements',
        'attributes': {'placementType': 'APP_PREVIEW' if video else 'APP_SCREENSHOT', 'placementGroup': group},
        'relationships': {media: relation(asset['type'], asset['id']),
                          'appStoreVersionLocalization': relation('appStoreVersionLocalizations', localization)},
    }})['data']


def review_image(api, product_id, path, replace=False):
    endpoint = '/v1/inAppPurchaseAppStoreReviewScreenshots'
    try:
        asset = api.request('GET', f'/v2/inAppPurchases/{product_id}/appStoreReviewScreenshot')['data']
    except AppleAPIError as error:
        if error.status != 404:
            raise
        asset = None
    checksum = hashlib.md5(path.read_bytes()).hexdigest()
    if asset:
        attributes = asset['attributes']
        state = (attributes.get('assetDeliveryState') or {}).get('state')
        # Apple renames processed originals to SOURCE. The checksum still
        # identifies the uploaded bytes and makes repeat uploads idempotent.
        if state == 'COMPLETE' and attributes.get('sourceFileChecksum') == checksum:
            print('Product review image', path.name, 'already ready', flush=True)
            return
        if state != 'AWAITING_UPLOAD' or attributes.get('fileName') != path.name:
            if not replace:
                raise RuntimeError('A different product review image exists; review it, then use --replace-purchase-reviews if replacement is intended')
            api.request('DELETE', f'{endpoint}/{asset["id"]}')
            asset = None
    if asset is None:
        asset = api.request('POST', endpoint, {'data': {
            'type': endpoint.split('/')[-1],
            'attributes': {'fileName': path.name, 'fileSize': path.stat().st_size},
            'relationships': {'inAppPurchaseV2': relation('inAppPurchases', product_id)},
        }})['data']
    state = (asset['attributes'].get('assetDeliveryState') or {}).get('state')
    if state == 'AWAITING_UPLOAD':
        upload_parts(path, asset['attributes']['uploadOperations'])
        api.request('PATCH', f'{endpoint}/{asset["id"]}', {'data': {
            'type': asset['type'], 'id': asset['id'], 'attributes': {
                'uploaded': True, 'sourceFileChecksum': checksum,
            },
        }})
    wait_ready(api, endpoint, asset['id'], review=True)
    print('Product review image', path.name, 'ready', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('media_root', type=Path)
    parser.add_argument('--localization', required=True, help='Editable App Store version localization ID')
    parser.add_argument('--purchase-reviews', action='store_true')
    parser.add_argument('--replace-purchase-reviews', action='store_true',
                        help='Replace existing product review images only when the reviewed bytes differ')
    args = parser.parse_args()
    api = AppStoreClient()
    app = api.request('GET', f'/v1/apps/{APP_ID}')['data']
    assert app['attributes']['bundleId'] == 'com.corsairlabs.ludocheer'
    library = api.request('GET', f'/v1/apps/{APP_ID}/assetLibrary')['data']['id']
    summary = []
    for folder, group in GROUPS.items():
        ordered = {'APP_SCREENSHOT': [], 'APP_PREVIEW': []}
        images = sorted(p for p in (args.media_root / folder).glob('*.png') if p.name[0].isdigit())
        if len(images) != 5:
            raise ValueError(f'{folder} requires all five visually reviewed native screenshots')
        for path in images:
            path = opaque_image(path)
            asset = library_asset(api, library, path)
            placement = place(api, asset, args.localization, group)
            ordered['APP_SCREENSHOT'].append(placement['id'])
            summary.append({'file': str(path), 'asset': asset['id'], 'placement': placement['id']})
        for path in sorted((args.media_root / folder).glob('app-preview*.mp4')):
            asset = library_asset(api, library, path, video=True)
            placement = place(api, asset, args.localization, group, video=True)
            ordered['APP_PREVIEW'].append(placement['id'])
            summary.append({'file': str(path), 'asset': asset['id'], 'placement': placement['id']})
        # Apple orders screenshots and previews independently, even when they
        # belong to the same device group. A mixed ordering request is rejected.
        for placement_type, identifiers in ordered.items():
            query = urllib.parse.urlencode({'filter[placementGroup]': group,
                                            'filter[placementType]': placement_type,
                                            'sort': 'placementGroupPosition', 'limit': 200})
            other = api.all(f'/v1/appStoreVersionLocalizations/{args.localization}/placements?{query}')
            identifiers.extend(row['id'] for row in other if row['id'] not in identifiers)
            if not identifiers:
                continue
            api.request('POST', '/v1/appAssetLibraryPlacementOrderingRequests', {'data': {
                'type': 'appAssetLibraryPlacementOrderingRequests', 'attributes': {'placementGroup': group},
                'relationships': {
                    'orderedPlacements': {'data': [{'type': 'appAssetLibraryPlacements', 'id': value} for value in identifiers]},
                    'appStoreVersionLocalization': relation('appStoreVersionLocalizations', args.localization),
                },
            }})
    if args.purchase_reviews:
        products = api.all(f'/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200')
        for product in products:
            path = args.media_root / 'iphone-6.9' / f'review-{product["attributes"]["productId"]}.png'
            if not path.is_file():
                raise ValueError(f'Missing purchase review image: {path.name}')
            review_image(api, product['id'], opaque_image(path), replace=args.replace_purchase_reviews)
    (args.media_root / 'apple-upload-summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main()
