// Verifies the teacher -> assignment -> student -> feedback Firestore path,
// then removes only the disposable documents and accounts created here.
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
const field = value => ({ stringValue: value });
const authRequest = (operation, body) => fetch(
  `https://identitytoolkit.googleapis.com/v1/accounts:${operation}?key=${apiKey}`,
  { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) },
);
const signup = async label => {
  const response = await authRequest('signUp', {
    email: `chembalance-${label}-${crypto.randomUUID()}@example.test`,
    password: crypto.randomBytes(24).toString('base64url'), returnSecureToken: true,
  });
  if (!response.ok) throw new Error(`${label} signup HTTP ${response.status}`);
  return response.json();
};
const request = (token, target, method = 'GET', fields) => fetch(`${base}/${target}`, {
  method, headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  ...(fields ? { body: JSON.stringify({ fields }) } : {}),
});
(async () => {
  await requireAuth({ project, nonInteractive: true, ...getProjectDefaultAccount(process.cwd()) });
  const admin = new Client({ urlPrefix: 'https://firestore.googleapis.com', auth: true });
  const id = `qa-${crypto.randomUUID()}`, assignment = 'assignment', created = [];
  let teacher, student;
  try {
    teacher = await signup('teacher'); student = await signup('student');
    let response = await request(teacher.idToken, `users/${teacher.localId}`, 'PATCH', {
      name: field('QA Teacher'), email: field(teacher.email), role: field('teacher'), school: field('QA'),
    });
    if (!response.ok) throw new Error(`Teacher profile HTTP ${response.status}`);
    created.push(`users/${teacher.localId}`);
    response = await request(student.idToken, `users/${student.localId}`, 'PATCH', {
      name: field('QA Student'), email: field(student.email), role: field('student'), school: field('QA'),
    });
    if (!response.ok) throw new Error(`Student profile HTTP ${response.status}`);
    created.push(`users/${student.localId}`);
    response = await request(teacher.idToken, `classes/${id}`, 'PATCH', {
      name: field('QA Chemistry'), code: field('QA1234'), ownerId: field(teacher.localId),
      teacherName: field('QA Teacher'), createdAt: { timestampValue: new Date().toISOString() },
    });
    if (!response.ok) throw new Error(`Class create HTTP ${response.status}`);
    created.push(`classes/${id}`);
    response = await request(student.idToken, `classes/${id}/members/${student.localId}`, 'PATCH', {
      userId: field(student.localId), name: field('QA Student'), joinedAt: { timestampValue: new Date().toISOString() },
    });
    if (!response.ok) throw new Error(`Member create HTTP ${response.status}`);
    created.push(`classes/${id}/members/${student.localId}`);
    response = await request(student.idToken, `users/${student.localId}/memberships/${id}`, 'PATCH', {
      classId: field(id), joinedAt: { timestampValue: new Date().toISOString() },
    });
    if (!response.ok) throw new Error(`Membership create HTTP ${response.status}`);
    created.push(`users/${student.localId}/memberships/${id}`);
    response = await request(teacher.idToken, `classes/${id}/assignments/${assignment}`, 'PATCH', {
      title: field('Balance water'), equation: field('H2 + O2 -> H2O'), instructions: field('Show steps'),
      dueAt: { timestampValue: new Date(Date.now() + 86400000).toISOString() },
      createdAt: { timestampValue: new Date().toISOString() },
    });
    if (!response.ok) throw new Error(`Assignment create HTTP ${response.status}`);
    created.push(`classes/${id}/assignments/${assignment}`);
    response = await request(student.idToken,
      `classes/${id}/assignments/${assignment}/submissions/${student.localId}`, 'PATCH', {
        studentId: field(student.localId), studentName: field('QA Student'), answer: field('2H2 + O2 -> 2H2O'),
        status: field('submitted'), feedback: field(''), score: { nullValue: null },
        submittedAt: { timestampValue: new Date().toISOString() },
      });
    if (!response.ok) throw new Error(`Submission create HTTP ${response.status}`);
    created.push(`classes/${id}/assignments/${assignment}/submissions/${student.localId}`);
    response = await request(teacher.idToken,
      `classes/${id}/assignments/${assignment}/submissions/${student.localId}`, 'PATCH', {
        studentId: field(student.localId), studentName: field('QA Student'), answer: field('2H2 + O2 -> 2H2O'),
        status: field('reviewed'), feedback: field('Correct'), score: { integerValue: '100' },
        submittedAt: { timestampValue: new Date().toISOString() },
        reviewedAt: { timestampValue: new Date().toISOString() },
      });
    if (!response.ok) throw new Error(`Teacher feedback HTTP ${response.status}`);
    response = await request(student.idToken,
      `classes/${id}/assignments/${assignment}/submissions/${student.localId}`);
    const result = response.ok ? await response.json() : null;
    if (!result || result.fields.feedback.stringValue !== 'Correct') throw new Error('Feedback read failed');
    console.log('PASS: class, membership, assignment, submission and teacher feedback');
  } finally {
    for (const target of created.reverse()) {
      try { await admin.delete(`/v1/projects/${project}/databases/(default)/documents/${target}`); }
      catch (error) { if (error.status !== 404) throw error; }
    }
    for (const user of [teacher, student]) {
      if (user) await authRequest('delete', { idToken: user.idToken });
    }
    console.log('Disposable learning QA data removed.');
  }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
