const assert = require('node:assert/strict');
const { test } = require('node:test');
const { selection } = require('./mobile-release.cjs');
const pr = { event: 'pull_request', action: 'closed', merged: true, base: 'main' };

for (const platform of ['ios', 'android']) {
  test(`${platform} label uploads only its platform for shared changes`, () => {
    assert.deepEqual(selection({ ...pr, labels: [`release:${platform}`], files: ['client-flutter/lib/main.dart'] }),
      { platform, upload: true, reason: `PR label release:${platform}` });
  });
  test(`${platform} PR verification does not upload`, () => {
    assert.equal(selection({ ...pr, action: 'synchronize', merged: false, labels: [`release:${platform}`],
      files: [`client-flutter/${platform}/native-file`] }).upload, false);
  });
}
test('docs and backend changes do not build either mobile app', () => {
  assert.equal(selection({ ...pr, files: ['docs/ios-release.md', 'README.md', 'backend-cloudflare/src/index.ts'] }).platform, '');
});
test('missing or conflicting platform labels cannot publish', () => {
  for (const labels of [[], ['release:ios', 'release:android']]) {
    assert.throws(() => selection({ ...pr, labels, files: ['client-flutter/pubspec.yaml'] }), /exactly one/);
  }
});
test('unmerged close does not publish', () => {
  assert.equal(selection({ ...pr, merged: false, labels: ['release:ios'], files: ['client-flutter/lib/main.dart'] }).upload, false);
});
test('manual release requires main and a single known platform', () => {
  assert.throws(() => selection({ event: 'workflow_dispatch', base: 'feature', platform: 'ios' }), /main/);
  assert.throws(() => selection({ event: 'workflow_dispatch', base: 'main', platform: 'both' }), /Choose/);
  assert.equal(selection({ event: 'workflow_dispatch', base: 'main', platform: 'ios' }).upload, true);
});
test('a native-only change cannot select the opposite platform', () => {
  assert.throws(() => selection({ ...pr, labels: ['release:ios'], files: ['client-flutter/android/app/build.gradle'] }), /native-only/);
});
