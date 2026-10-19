// Tests sans réseau et sans clé réelle : clé ES256 éphémère générée ici, fetch factice.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync, verify as cryptoVerify } from 'node:crypto';
import {
  AscError, assertConfirmed, compareVersions, makeClient, makeToken, parseEnvFile,
  planControls, readLocalVersions, waitForBuild,
} from './asc.mjs';

const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });
const API = 'https://api.appstoreconnect.apple.com';

test('jeton ES256 : en-tête, charge utile, signature vérifiée avec la clé publique', () => {
  const tok = makeToken({ keyId: 'KID123', issuerId: 'ISS', privateKeyPem: pem, now: 1000 });
  const [h, p, s] = tok.split('.');
  assert.deepEqual(JSON.parse(Buffer.from(h, 'base64url')), { alg: 'ES256', kid: 'KID123', typ: 'JWT' });
  assert.deepEqual(JSON.parse(Buffer.from(p, 'base64url')), { iss: 'ISS', iat: 1000, exp: 2200, aud: 'appstoreconnect-v1' });
  const ok = cryptoVerify('sha256', Buffer.from(`${h}.${p}`), { key: publicKey, dsaEncoding: 'ieee-p1363' }, Buffer.from(s, 'base64url'));
  assert.equal(ok, true);
});

test('parseEnvFile : guillemets, commentaires et lignes vides', () => {
  assert.deepEqual(parseEnvFile('# c\n\nASC_KEY_ID="ABC"\nASC_ISSUER_ID=xyz\n'), { ASC_KEY_ID: 'ABC', ASC_ISSUER_ID: 'xyz' });
});

test('garde OK-APPLE : seule la valeur exacte passe', () => {
  assert.doesNotThrow(() => assertConfirmed('OK-APPLE'));
  for (const v of [undefined, '', 'ok-apple', 'OK-APPLE ', 'oui']) {
    assert.throws(() => assertConfirmed(v), /OK-APPLE/);
  }
});

test('comparaison de versions et de builds', () => {
  assert.ok(compareVersions('1.3.0', '1.2.0') > 0);
  assert.equal(compareVersions('1.3', '1.3.0'), 0);
  assert.ok(compareVersions('16', '9') > 0);
  assert.ok(compareVersions('1.10.0', '1.9.9') > 0);
});

test('lecture des versions du projet : cohérentes ou refus', () => {
  const txt = 'CURRENT_PROJECT_VERSION = 16;\nMARKETING_VERSION = 1.3.0;\nCURRENT_PROJECT_VERSION = 16;\nMARKETING_VERSION = "1.3.0";';
  assert.deepEqual(readLocalVersions(txt), { marketingVersion: '1.3.0', buildNumber: '16' });
  assert.throws(() => readLocalVersions('MARKETING_VERSION = 1.3.0;\nMARKETING_VERSION = 1.2.0;\nCURRENT_PROJECT_VERSION = 16;'));
});

test('contrôles des numéros : version, build, conflit de version en préparation', () => {
  const base = { marketingVersion: '1.3.0', buildNumber: '16', liveVersion: '1.2.0', maxBuild: '15', editable: [] };
  assert.equal(planControls(base).ok, true);
  assert.equal(planControls({ ...base, marketingVersion: '1.2.0' }).ok, false);
  assert.equal(planControls({ ...base, buildNumber: '15' }).ok, false);
  assert.equal(planControls({ ...base, editable: [{ id: 'a', versionString: '1.4.0', appStoreState: 'PREPARE_FOR_SUBMISSION' }] }).ok, false);
  const same = planControls({ ...base, editable: [{ id: 'a', versionString: '1.3.0', appStoreState: 'PREPARE_FOR_SUBMISSION' }] });
  assert.equal(same.ok, true);
  assert.equal(same.reuseVersionId, 'a');
  assert.equal(planControls({ ...base, liveVersion: null, maxBuild: null }).ok, true);
});

test('client : GET sans corps, POST en JSON, jeton Bearer, erreur Apple sans jeton', async () => {
  const calls = [];
  const fakeFetch = async (url, init) => {
    calls.push({ url: String(url), init });
    if (String(url).includes('/bad')) {
      return new Response(JSON.stringify({ errors: [{ title: 'NOT_AUTHORIZED', detail: 'clé refusée' }] }), { status: 401 });
    }
    return new Response(JSON.stringify({ data: [] }), { status: 200 });
  };
  const client = makeClient({ keyId: 'K', issuerId: 'I', privateKeyPem: pem }, { fetchImpl: fakeFetch, nowFn: () => 1000 });

  await client.get('/v1/apps', { 'filter[bundleId]': 'com.x' });
  assert.equal(calls[0].url, `${API}/v1/apps?filter%5BbundleId%5D=com.x`);
  assert.equal(calls[0].init.method, 'GET');
  assert.equal(calls[0].init.body, undefined);
  assert.match(calls[0].init.headers.Authorization, /^Bearer [\w-]+\.[\w-]+\.[\w-]+$/);

  await client.post('/v1/appStoreVersions', { data: { type: 'appStoreVersions' } });
  assert.equal(calls[1].init.headers['Content-Type'], 'application/json');
  assert.equal(JSON.parse(calls[1].init.body).data.type, 'appStoreVersions');

  await assert.rejects(client.get('/bad'), (e) =>
    e instanceof AscError && e.status === 401 && /clé refusée/.test(e.message) && !/Bearer/.test(e.message));
});

test('attente du build : VALID rend la main, FAILED arrête, borne respectée', async () => {
  const noSleep = async () => {};
  const quiet = () => {};
  const seq = ['PROCESSING', 'VALID'];
  const okClient = { get: async () => ({ data: [{ id: 'b1', attributes: { version: '16', processingState: seq.shift() } }] }) };
  const b = await waitForBuild(okClient, 'app', '16', { sleepFn: noSleep, log: quiet, tries: 5, ms: 0 });
  assert.equal(b.id, 'b1');

  const failClient = { get: async () => ({ data: [{ id: 'b2', attributes: { version: '16', processingState: 'FAILED' } }] }) };
  await assert.rejects(waitForBuild(failClient, 'app', '16', { sleepFn: noSleep, log: quiet, tries: 5, ms: 0 }), /refusé/);

  const slowClient = { get: async () => ({ data: [{ id: 'b3', attributes: { version: '16', processingState: 'PROCESSING' } }] }) };
  await assert.rejects(waitForBuild(slowClient, 'app', '16', { sleepFn: noSleep, log: quiet, tries: 3, ms: 0 }), /3 essais/);
});
