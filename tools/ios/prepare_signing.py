"""Install the existing shared certificate into an ephemeral CI keychain."""
import argparse
import base64
from datetime import datetime, timezone
import os
from pathlib import Path
import plistlib
import secrets
import shutil
import subprocess


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cleanup', action='store_true')
    args = parser.parse_args()
    temporary = Path(os.environ['RUNNER_TEMP'])
    signing = temporary / 'ludo-ios-signing'
    keychain = signing / 'signing.keychain-db'
    profile_record = signing / 'installed-profile.txt'
    if args.cleanup:
        if keychain.exists():
            subprocess.run(['security', 'delete-keychain', str(keychain)], check=False)
        if profile_record.exists():
            profile_path = Path(profile_record.read_text())
            expected = Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles'
            if profile_path.parent != expected:
                raise RuntimeError('Refusing to remove a profile outside the CI profile directory')
            profile_path.unlink(missing_ok=True)
        if signing.exists() and signing.resolve().parent == temporary.resolve():
            shutil.rmtree(signing)
        (temporary / 'ExportOptions.plist').unlink(missing_ok=True)
        return

    required = ['IOS_DISTRIBUTION_P12_BASE64', 'IOS_DISTRIBUTION_P12_PASSWORD',
                'IOS_PROVISION_PROFILE_BASE64', 'APPLE_TEAM_ID', 'IOS_BUNDLE_ID']
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        raise RuntimeError('Missing signing configuration: ' + ', '.join(missing))
    signing.mkdir(mode=0o700, exist_ok=True)
    p12 = signing / 'distribution.p12'
    profile = signing / 'app.mobileprovision'
    p12.write_bytes(base64.b64decode(os.environ['IOS_DISTRIBUTION_P12_BASE64'], validate=True))
    profile.write_bytes(base64.b64decode(os.environ['IOS_PROVISION_PROFILE_BASE64'], validate=True))
    decoded = run('security', 'cms', '-D', '-i', str(profile), capture_output=True).stdout
    metadata = plistlib.loads(decoded)
    team = os.environ['APPLE_TEAM_ID']
    bundle = os.environ['IOS_BUNDLE_ID']
    entitlements = metadata['Entitlements']
    assert metadata['TeamIdentifier'] == [team], 'Wrong Apple signing team'
    assert entitlements['application-identifier'] == f'{team}.{bundle}', 'Wrong app profile'
    assert entitlements.get('com.apple.developer.game-center') is True, 'Game Center is missing'
    assert not entitlements.get('get-task-allow'), 'A development profile cannot upload to TestFlight'
    assert not metadata.get('ProvisionedDevices'), 'Use an App Store Connect profile'
    assert metadata['ExpirationDate'].replace(tzinfo=timezone.utc) > datetime.now(timezone.utc)
    import hashlib
    # Current existing shared identity 3VL35NY5JS. The prior shared identity
    # was revoked during the owner's November 16 signing rotation.
    expected_certificate = '85f00acd827b39f9785e92da5c5e64f56d2c807526450fa07c5b24c0fe7199d0'
    assert any(hashlib.sha256(cert).hexdigest() == expected_certificate
               for cert in metadata['DeveloperCertificates']), 'Profile must use the existing shared certificate'

    password = secrets.token_hex(32)
    print(f'::add-mask::{password}')
    run('security', 'create-keychain', '-p', password, str(keychain))
    run('security', 'set-keychain-settings', '-lut', '7200', str(keychain))
    run('security', 'unlock-keychain', '-p', password, str(keychain))
    run('security', 'import', str(p12), '-P', os.environ['IOS_DISTRIBUTION_P12_PASSWORD'],
        '-A', '-t', 'cert', '-f', 'pkcs12', '-k', str(keychain))
    run('security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:',
        '-k', password, str(keychain), stdout=subprocess.DEVNULL)
    identities = run('security', 'find-identity', '-v', '-p', 'codesigning',
                     str(keychain), capture_output=True).stdout.decode()
    matching_certificates = [cert for cert in metadata['DeveloperCertificates']
                             if hashlib.sha256(cert).hexdigest() == expected_certificate]
    if not any(hashlib.sha1(cert).hexdigest().upper() in identities.upper()
               for cert in matching_certificates):
        raise RuntimeError('The stored signing identity is invalid or does not match the profile. '
                           'Check certificate revocation, expiry, and the matching PKCS#12 secrets.')
    run('security', 'list-keychains', '-d', 'user', '-s', str(keychain), 'login.keychain-db')
    installed = Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles' / f"{metadata['UUID']}.mobileprovision"
    installed.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(profile, installed)
    profile_record.write_text(str(installed))
    export = {
        'method': 'app-store-connect', 'teamID': team, 'signingStyle': 'manual',
        'signingCertificate': 'Apple Distribution', 'uploadSymbols': True,
        'provisioningProfiles': {bundle: metadata['Name']},
    }
    (temporary / 'ExportOptions.plist').write_bytes(plistlib.dumps(export))
    ruby = '''require 'xcodeproj'
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
project.targets.find { |t| t.name == 'Runner' }.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  c.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
  c.build_settings['PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]'] = ENV.fetch('LUDO_PROFILE_NAME')
end
project.save
'''
    run('bundle', 'exec', 'ruby', '-e', ruby,
        env={**os.environ, 'LUDO_PROFILE_NAME': metadata['Name']})
    print('Installed the existing Apple Distribution certificate and Ludo Cheer Game Center profile.')


if __name__ == '__main__':
    main()
