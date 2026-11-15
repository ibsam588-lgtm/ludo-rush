"""Configure Ludo Cheer's Apple catalog without submitting products for review."""
from decimal import Decimal
import json
from pathlib import Path

from app_store_api import AppStoreClient, AppleAPIError

APP_ID = '6834993861'


def relation(kind, identifier):
    return {'data': {'type': kind, 'id': identifier}}


def main():
    api = AppStoreClient()
    app = api.request('GET', f'/v1/apps/{APP_ID}')['data']
    assert app['attributes']['bundleId'] == 'com.corsairlabs.ludocheer'
    catalog = json.loads(Path(__file__).with_name('iap_catalog.json').read_text())
    existing = {p['attributes']['productId']: p for p in
                api.all(f'/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200')}
    territories = api.all('/v1/territories?limit=200')
    summary = []
    for item in catalog:
        expected_type = 'CONSUMABLE' if item['consumable'] else 'NON_CONSUMABLE'
        product = existing.get(item['id'])
        if product is None:
            product = api.request('POST', '/v2/inAppPurchases', {'data': {
                'type': 'inAppPurchases', 'attributes': {
                    'name': item['name'], 'productId': item['id'],
                    'inAppPurchaseType': expected_type,
                    'reviewNote': 'Open Shop from the lobby. Purchases are verified by the server before delivery. Restore Purchases restores permanent cosmetic items.',
                    'familySharable': False,
                }, 'relationships': {'app': relation('apps', APP_ID)},
            }})['data']
        assert product['attributes']['inAppPurchaseType'] == expected_type
        identifier = product['id']
        localizations = api.all(f'/v2/inAppPurchases/{identifier}/inAppPurchaseLocalizations?limit=200')
        if not any(row['attributes']['locale'] == 'en-US' for row in localizations):
            api.request('POST', '/v1/inAppPurchaseLocalizations', {'data': {
                'type': 'inAppPurchaseLocalizations', 'attributes': {
                    'locale': 'en-US', 'name': item['name'], 'description': item['description'],
                }, 'relationships': {'inAppPurchaseV2': relation('inAppPurchases', identifier)},
            }})
        try:
            api.request('GET', f'/v2/inAppPurchases/{identifier}/iapPriceSchedule')
        except AppleAPIError as error:
            if error.status != 404:
                raise
            points = api.all(f'/v2/inAppPurchases/{identifier}/pricePoints?filter%5Bterritory%5D=USA&limit=200')
            point = next(p for p in points if Decimal(p['attributes']['customerPrice']) == Decimal(item['usd']))
            temporary_id = '${usa-base-price}'
            api.request('POST', '/v1/inAppPurchasePriceSchedules', {
                'data': {'type': 'inAppPurchasePriceSchedules', 'relationships': {
                    'inAppPurchase': relation('inAppPurchases', identifier),
                    'baseTerritory': relation('territories', 'USA'),
                    'manualPrices': {'data': [{'type': 'inAppPurchasePrices', 'id': temporary_id}]},
                }},
                'included': [{'type': 'inAppPurchasePrices', 'id': temporary_id,
                              'attributes': {'startDate': None, 'endDate': None},
                              'relationships': {
                                  'inAppPurchaseV2': relation('inAppPurchases', identifier),
                                  'inAppPurchasePricePoint': relation('inAppPurchasePricePoints', point['id']),
                              }}],
            })
        try:
            api.request('GET', f'/v2/inAppPurchases/{identifier}/inAppPurchaseAvailability')
        except AppleAPIError as error:
            if error.status != 404:
                raise
            api.request('POST', '/v1/inAppPurchaseAvailabilities', {'data': {
                'type': 'inAppPurchaseAvailabilities',
                'attributes': {'availableInNewTerritories': True},
                'relationships': {
                    'inAppPurchase': relation('inAppPurchases', identifier),
                    'availableTerritories': {'data': [{'type': 'territories', 'id': t['id']} for t in territories]},
                },
            }})
        summary.append({'productId': item['id'], 'appleId': identifier,
                        'type': expected_type, 'usd': item['usd']})
        print('Configured', item['id'], identifier, expected_type, 'USD', item['usd'], flush=True)
    output = Path('client-flutter/build/ios-setup/catalog-summary.json')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
