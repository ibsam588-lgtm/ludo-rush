// Shared files never infer both platforms. A PR label states release intent.
function selection({ event, action, merged, base, labels = [], files = [], platform }) {
  if (event === 'workflow_dispatch') {
    if (base !== 'main') throw new Error('Mobile uploads must run from main.');
    if (!['ios', 'android'].includes(platform)) throw new Error('Choose ios or android.');
    return { platform, upload: true, reason: 'Manual release from main' };
  }
  if (base !== 'main' || (action === 'closed' && !merged)) {
    return { platform: '', upload: false, reason: 'No merged main release' };
  }
  const relevant = files.filter(path => /^(client-flutter\/|tools\/ios\/|fastlane\/ios\/|\.github\/workflows\/(mobile-release|flutter-ios-testflight|flutter-android-internal)\.yml$|\.github\/scripts\/mobile-release)/.test(path));
  if (!relevant.length) return { platform: '', upload: false, reason: 'No mobile source changes' };
  const chosen = ['ios', 'android'].filter(p => labels.includes(`release:${p}`));
  if (chosen.length !== 1) throw new Error('Add exactly one PR label: release:ios or release:android. Shared resources do not select both.');
  const selected = chosen[0];
  const native = relevant.filter(path => /^client-flutter\/(ios|android)\//.test(path));
  if (native.length === relevant.length && native.every(path => !path.startsWith(`client-flutter/${selected}/`))) {
    throw new Error(`The release:${selected} label does not match these native-only changes.`);
  }
  return { platform: selected, upload: action === 'closed' && merged, reason: `PR label release:${selected}` };
}

module.exports = async ({ github, context, core }) => {
  const pr = context.payload.pull_request;
  const files = pr ? await github.paginate(github.rest.pulls.listFiles, {
    ...context.repo, pull_number: pr.number, per_page: 100,
  }) : [];
  const result = selection({
    event: context.eventName, action: context.payload.action,
    merged: pr?.merged === true,
    base: pr?.base.ref || context.ref.replace('refs/heads/', ''),
    labels: (pr?.labels || []).map(label => label.name),
    files: files.map(file => file.filename), platform: context.payload.inputs?.platform,
  });
  core.setOutput('platform', result.platform);
  core.setOutput('upload', String(result.upload));
  await core.summary.addHeading('Mobile release selection')
    .addRaw(`${result.reason}. ${result.platform ? `${result.platform}: ${result.upload ? 'build and upload' : 'verify only'}` : 'No mobile build'}.`)
    .write();
};
module.exports.selection = selection;
