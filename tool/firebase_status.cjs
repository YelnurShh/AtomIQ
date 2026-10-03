// Read-only diagnostics. Uses the existing Firebase CLI session; never logs tokens.
const path = require('node:path');
const root = process.env.FIREBASE_TOOLS_LIB;
if (!root) throw new Error('Set FIREBASE_TOOLS_LIB to the Firebase CLI lib directory.');
const { requireAuth } = require(path.join(root, 'requireAuth'));
const { Client } = require(path.join(root, 'apiv2'));
const { getProjectDefaultAccount } = require(path.join(root, 'auth'));
const project = 'alhimic-a152b';
(async () => {
  const account = getProjectDefaultAccount(process.cwd());
  await requireAuth({ project, nonInteractive: true, ...account });
  const auth = new Client({ urlPrefix: 'https://identitytoolkit.googleapis.com', auth: true });
  for (const [label, endpoint] of [
    ['authentication', `/admin/v2/projects/${project}/config`],
    ['google', `/admin/v2/projects/${project}/defaultSupportedIdpConfigs/google.com`],
  ]) {
    try {
      const { body } = await auth.get(endpoint, { headers: { 'x-goog-user-project': project } });
      console.log(label, JSON.stringify(label === 'google' ? { enabled: body.enabled, hasClientId: !!body.clientId } : { emailEnabled: body.signIn?.email?.enabled, passwordRequired: body.signIn?.email?.passwordRequired }));
    } catch (e) { console.log(label, e.status || e.message); }
  }
  const store = new Client({ urlPrefix: 'https://firestore.googleapis.com', auth: true });
  const { body } = await store.get(`/v1/projects/${project}/databases`);
  console.log('databases', JSON.stringify((body.databases || []).map(d => ({ name: d.name, locationId: d.locationId }))));
  const rules = new Client({ urlPrefix: 'https://firebaserules.googleapis.com', auth: true });
  try {
    const release = await rules.get(`/v1/projects/${project}/releases/cloud.firestore`);
    const ruleset = await rules.get(`/v1/${release.body.rulesetName}`);
    console.log('firestoreRules', JSON.stringify(ruleset.body.source.files));
  } catch (e) { console.log('firestoreRules', e.status || e.message); }
})().catch(e => { console.error(e.message); process.exitCode = 1; });
