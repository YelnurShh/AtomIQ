// Creates one disposable account to verify the deployed rules, then removes only
// that account and its two exact documents. Never prints passwords or tokens.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = process.env.FIREBASE_TOOLS_LIB;
const { requireAuth } = require(path.join(root, 'requireAuth'));
const { getProjectDefaultAccount } = require(path.join(root, 'auth'));
const { Client } = require(path.join(root, 'apiv2'));
const config = JSON.parse(fs.readFileSync('android/app/google-services.json', 'utf8'));
const project = config.project_info.project_id;
if (project !== 'alhimic-a152b') throw new Error('Unexpected project');
const apiKey = config.client[0].api_key[0].current_key;
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const field = s => ({ stringValue: s });
let uid, token;
const authRequest = async (operation, body) => fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${operation}?key=${apiKey}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
});
(async () => {
  await requireAuth({ project, nonInteractive: true, ...getProjectDefaultAccount(process.cwd()) });
  const admin = new Client({ urlPrefix: 'https://firestore.googleapis.com', auth: true });
  try {
    const email = `chembalance-qa-${crypto.randomUUID()}@example.test`;
    const signup = await authRequest('signUp', { email, password: crypto.randomBytes(24).toString('base64url'), returnSecureToken: true });
    if (!signup.ok) throw new Error(`Email signup HTTP ${signup.status}`);
    const user = await signup.json(); uid = user.localId; token = user.idToken;
    const request = (target, method = 'GET', body) => fetch(`${base}/${target}`, {
      method, headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const profile = { fields: { name: field('Disposable QA'), email: field(email), role: field('student'), school: field('QA') } };
    let response = await request(`users/${uid}`, 'PATCH', profile);
    if (!response.ok) throw new Error(`Profile write HTTP ${response.status}`);
    response = await request(`users/${uid}/checks/smoke`, 'PATCH', { fields: {
      equation: field('2H2 + O2 -> 2H2O'), answer: field('Balanced'), isBalanced: { booleanValue: true }, createdAt: { timestampValue: new Date().toISOString() },
    } });
    if (!response.ok) throw new Error(`Result write HTTP ${response.status}`);
    response = await request(`users/${uid}/checks/smoke`);
    if (!response.ok || (await response.json()).fields.answer.stringValue !== 'Balanced') throw new Error('Result read failed');
    response = await request('users/not-my-account');
    if (response.status !== 403) throw new Error('Cross-user read was not denied');
    profile.fields.role = field('teacher');
    response = await request(`users/${uid}`, 'PATCH', profile);
    if (response.status !== 403) throw new Error('Role escalation was not denied');
    console.log('PASS: email signup, Firestore profile/result write/read, cross-user denial, role escalation denial');
  } finally {
    if (uid) {
      for (const suffix of [`users/${uid}/checks/smoke`, `users/${uid}`]) {
        try { await admin.delete(`/v1/projects/${project}/databases/(default)/documents/${suffix}`); }
        catch (e) { if (e.status !== 404) throw e; }
      }
      const removed = await authRequest('delete', { idToken: token });
      if (!removed.ok) throw new Error(`QA account cleanup HTTP ${removed.status}`);
      console.log('Disposable QA account and documents removed.');
    }
  }
})().catch(e => { console.error(e.message); process.exitCode = 1; });
