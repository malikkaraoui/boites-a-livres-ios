// Tests sans réseau et sans clé réelle : clé ES256 éphémère générée ici, fetch factice.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync, verify as cryptoVerify } from 'node:crypto';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  AscError, assertConfirmed, checkNotes, compareVersions, listVersions, makeClient, makeToken, parseEnvFile,
  planControls, preflight, publish, readLocalVersions, waitForBuild,
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

// Régression : la version en ligne est en 11e position (au-delà de l'ancienne limite de 10).
const APP = 'APP1';
const v = (id, versionString, appStoreState) => ({ id, attributes: { versionString, appStoreState } });
// Première page : dix versions anciennes, « non éditables » (la cause du refus doit être la règle de version).
// Seconde page : la version en ligne en 11e position, ou une version en revue si `second` la remplace.
function pagedClient(second = [v('live', '1.3.0', 'READY_FOR_SALE')], { writes = [] } = {}) {
  const first = Array.from({ length: 10 }, (_, i) => v(`r${i}`, `1.0.${i}`, 'REPLACED_WITH_NEW_VERSION'));
  return {
    get: async (path) => {
      const p = String(path);
      if (p === '/v1/apps') return { data: [{ id: APP, attributes: { name: 'x' } }] };
      if (p.includes('cursor=2')) return { data: second, links: {} };
      if (p.includes(`/v1/apps/${APP}/appStoreVersions`)) {
        return { data: first, links: { next: `${API}/v1/apps/${APP}/appStoreVersions?cursor=2` } };
      }
      if (p === '/v1/builds') return { data: [] };
      throw new Error(`appel inattendu en test : ${p}`);
    },
    post: async (p) => { writes.push(`POST ${p}`); throw new Error('écriture inattendue en test'); },
    patch: async (p) => { writes.push(`PATCH ${p}`); throw new Error('écriture inattendue en test'); },
  };
}

const LOCAL_1_4 = { marketingVersion: '1.4.0', buildNumber: '17' };
function notesFile(text) {
  const dir = mkdtempSync(join(tmpdir(), 'asc-notes-'));
  const file = join(dir, 'fr-FR.txt');
  writeFileSync(file, text);
  return file;
}

test('listVersions lit toutes les pages (version en ligne en 11e position)', async () => {
  const all = await listVersions(pagedClient(), APP);
  assert.equal(all.length, 11);
  assert.ok(all.some((x) => x.attributes.appStoreState === 'READY_FOR_SALE'));
});

test('publish refuse AVANT tout xcodebuild si la version locale n\'est pas supérieure à la version en ligne', async () => {
  const calls = [];
  await assert.rejects(
    publish({
      client: pagedClient(), cfg: { keyPath: '/inexistant.p8' }, confirm: 'OK-APPLE', log: () => {},
      localOverride: { marketingVersion: '1.3.0', buildNumber: '16' },
      runXcodeFn: (args) => calls.push(args),
    }),
    (e) => /version locale 1\.3\.0 non supérieure/.test(e.message) && !/arrêt à l'étape/.test(e.message),
  );
  assert.equal(calls.length, 0);
});

test('preflight refuse une version en revue située sur la 2e page, avant tout archive', async () => {
  const writes = [];
  const calls = [];
  const client = pagedClient([v('rev', '1.4.0', 'WAITING_FOR_REVIEW')], { writes });
  await assert.rejects(
    publish({
      client, cfg: { keyPath: '/inexistant.p8' }, confirm: 'OK-APPLE', log: () => {},
      localOverride: LOCAL_1_4, notesPath: notesFile('Corrections.'), runXcodeFn: (args) => calls.push(args),
    }),
    (e) => /WAITING_FOR_REVIEW/.test(e.message) && /Rien n'a été envoyé/.test(e.message),
  );
  assert.equal(calls.length, 0, 'aucun xcodebuild lancé');
  assert.deepEqual(writes, [], 'aucune écriture App Store Connect');
});

test('preflight refuse des notes vides ou trop longues', async () => {
  const client = pagedClient();
  await assert.rejects(preflight({ client, log: () => {}, local: LOCAL_1_4, notesPath: notesFile('  \n') }), /vide/);
  await assert.rejects(preflight({ client, log: () => {}, local: LOCAL_1_4, notesPath: notesFile('x'.repeat(4001)) }), /trop longues/);
  assert.equal(checkNotes('Bonjour').ok, true);
  assert.equal(checkNotes('x'.repeat(4000)).ok, true);
});

test('preflight accepte une configuration valide (lecture seule)', async () => {
  const writes = [];
  const pf = await preflight({ client: pagedClient([v('live', '1.3.0', 'READY_FOR_SALE')], { writes }), log: () => {}, local: LOCAL_1_4, notesPath: notesFile('Corrections.') });
  assert.equal(pf.plan.ok, true);
  assert.equal(pf.notes, 'Corrections.');
  assert.deepEqual(writes, []);
});

test('preflight refuse une clé rejetée par Apple, sans rien lancer', async () => {
  const rejected = { get: async () => { throw Object.assign(new Error('HTTP 401'), { status: 401 }); } };
  await assert.rejects(preflight({ client: rejected, log: () => {}, local: LOCAL_1_4, notesPath: notesFile('ok') }), /clé refusée/);
});

test('listVersions refuse une pagination trop longue au lieu de tronquer', async () => {
  const endless = { get: async () => ({ data: [v('x', '1.0.0', 'REJECTED')], links: { next: `${API}/next` } }) };
  await assert.rejects(listVersions(endless, APP, 3), /trop longue/);
});
