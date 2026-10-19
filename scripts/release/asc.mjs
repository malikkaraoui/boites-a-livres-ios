// Client App Store Connect sans dépendance : JWT ES256 signé avec node:crypto, appels fetch.
// Usage : node scripts/release/asc.mjs check
//         node scripts/release/asc.mjs publish --confirm OK-APPLE   (appelé par `make release`)
// Identifiants : ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (environnement, ou ~/.appstoreconnect/config.env).
// Ne jamais afficher le contenu de la clé .p8 ni un jeton signé.
import { sign as cryptoSign } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const API = 'https://api.appstoreconnect.apple.com';
export const BUNDLE_ID = 'com.malikkaraoui.boitesalivresapp';
export const TEAM_ID = 'UPES5479T5';
export const SCHEME = 'BoitesALivresNative';
export const LOCALE = 'fr-FR';
export const CONFIRM_WORD = 'OK-APPLE';
export const NOTES_MAX = 4000;
const LIVE = 'READY_FOR_SALE';
const EDITABLE = ['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY'];
const POLL_TRIES = 40;
const POLL_MS = 30_000;
const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const BUILD_DIR = join(ROOT, '.build', 'release');
const ARCHIVE = join(BUILD_DIR, `${SCHEME}.xcarchive`);
const EXPORT_DIR = join(BUILD_DIR, 'export');
const EXPORT_PLIST = join(ROOT, 'scripts', 'release', 'ExportOptions.plist');
const PBXPROJ = join(ROOT, 'BoitesALivresNative.xcodeproj', 'project.pbxproj');
export const NOTES_PATH = join(ROOT, 'release-notes', `${LOCALE}.txt`);
// États d'attente ou de revue : tant qu'une version est là, on n'envoie rien (doc Apple : appStoreState).
export const EN_ATTENTE = ['WAITING_FOR_REVIEW', 'IN_REVIEW', 'PENDING_DEVELOPER_RELEASE', 'PROCESSING_FOR_APP_STORE', 'PENDING_APPLE_RELEASE'];

export class AscError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'AscError';
    this.status = status;
  }
}

// ---------- configuration ----------

export function parseEnvFile(text) {
  const out = {};
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const m = /^([A-Z_][A-Z0-9_]*)=(.*)$/.exec(line);
    if (!m) continue;
    let v = m[2].trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    out[m[1]] = v;
  }
  return out;
}

function expandPath(p) {
  return p.replace(/^\$HOME(?=\/|$)/, homedir()).replace(/^~(?=\/|$)/, homedir());
}

export function loadConfig(env = process.env, configPath = join(homedir(), '.appstoreconnect', 'config.env')) {
  const fromFile = existsSync(configPath) ? parseEnvFile(readFileSync(configPath, 'utf8')) : {};
  const get = (k) => env[k] || fromFile[k] || '';
  const cfg = { keyId: get('ASC_KEY_ID'), issuerId: get('ASC_ISSUER_ID'), keyPath: expandPath(get('ASC_KEY_PATH')) };
  const missing = Object.entries({ ASC_KEY_ID: cfg.keyId, ASC_ISSUER_ID: cfg.issuerId, ASC_KEY_PATH: cfg.keyPath })
    .filter(([, v]) => !v).map(([k]) => k);
  if (missing.length) throw new Error(`configuration incomplète (${missing.join(', ')}) : voir ${configPath}`);
  return cfg;
}

export function loadKey(keyPath) {
  if (!existsSync(keyPath)) throw new Error(`clé .p8 introuvable : ${keyPath}`);
  const mode = statSync(keyPath).mode & 0o777;
  if (mode & 0o077) throw new Error(`permissions trop ouvertes sur la clé (${mode.toString(8)}) : chmod 600 requis`);
  return readFileSync(keyPath, 'utf8');
}

// ---------- jeton et client HTTP ----------

export function makeToken({ keyId, issuerId, privateKeyPem, now = Math.floor(Date.now() / 1000) }) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const data = `${b64({ alg: 'ES256', kid: keyId, typ: 'JWT' })}.${b64({ iss: issuerId, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })}`;
  // ES256 : signature brute r||s (ieee-p1363), pas le DER par défaut.
  const sig = cryptoSign('sha256', Buffer.from(data), { key: privateKeyPem, dsaEncoding: 'ieee-p1363' });
  return `${data}.${sig.toString('base64url')}`;
}

export function makeClient({ keyId, issuerId, privateKeyPem }, { fetchImpl = fetch, nowFn = () => Math.floor(Date.now() / 1000) } = {}) {
  async function request(method, path, { query, body } = {}) {
    const url = new URL(path, API);
    for (const [k, v] of Object.entries(query ?? {})) url.searchParams.set(k, String(v));
    const token = makeToken({ keyId, issuerId, privateKeyPem, now: nowFn() });
    const hasBody = body !== undefined;
    const res = await fetchImpl(url, {
      method,
      headers: { Authorization: `Bearer ${token}`, ...(hasBody ? { 'Content-Type': 'application/json' } : {}) },
      body: hasBody ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    let json = {};
    try {
      json = text ? JSON.parse(text) : {};
    } catch {
      json = {};
    }
    if (!res.ok) {
      const detail = (json.errors ?? []).map((e) => `${e.title ?? ''} ${e.detail ?? ''}`.trim()).join(' | ') || text.slice(0, 200);
      throw new AscError(res.status, `${method} ${url.pathname} -> HTTP ${res.status} : ${detail}`);
    }
    return json;
  }
  return {
    get: (path, query) => request('GET', path, { query }),
    post: (path, body) => request('POST', path, { body }),
    patch: (path, body) => request('PATCH', path, { body }),
  };
}

// ---------- règles pures (testées) ----------

export function assertConfirmed(value) {
  if (value !== CONFIRM_WORD) {
    throw new Error(`refus : CONFIRMER=${CONFIRM_WORD} exact requis (reçu : "${value ?? ''}"). Aucune action lancée.`);
  }
}

const isNumeric = (s) => /^\d+(\.\d+)*$/.test(String(s));

export function compareVersions(a, b) {
  const pa = String(a).split('.').map(Number);
  const pb = String(b).split('.').map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] || 0) - (pb[i] || 0);
    if (d) return Math.sign(d);
  }
  return 0;
}

export function readLocalVersions(pbxprojText) {
  const grab = (key) => [...new Set([...pbxprojText.matchAll(new RegExp(`${key} = ([^;]+);`, 'g'))].map((m) => m[1].trim().replace(/"/g, '')))];
  const mv = grab('MARKETING_VERSION');
  const cb = grab('CURRENT_PROJECT_VERSION');
  if (mv.length !== 1 || cb.length !== 1) {
    throw new Error(`versions incohérentes dans project.pbxproj : MARKETING_VERSION=${mv.join(',')} CURRENT_PROJECT_VERSION=${cb.join(',')}`);
  }
  return { marketingVersion: mv[0], buildNumber: cb[0] };
}

export function planControls({ marketingVersion, buildNumber, liveVersion, maxBuild, editable }) {
  const refus = (reason) => ({ ok: false, reason });
  if (!isNumeric(marketingVersion) || !isNumeric(buildNumber)) return refus(`numéros illisibles (${marketingVersion} / ${buildNumber})`);
  if (liveVersion && compareVersions(marketingVersion, liveVersion) <= 0) {
    return refus(`version locale ${marketingVersion} non supérieure à la version en ligne ${liveVersion}`);
  }
  if (maxBuild && compareVersions(buildNumber, maxBuild) <= 0) {
    return refus(`build ${buildNumber} non supérieur au dernier build reçu (${maxBuild})`);
  }
  const other = editable.find((v) => v.versionString !== marketingVersion);
  if (other) {
    return refus(`une version en préparation existe déjà (${other.versionString}, ${other.appStoreState}) : à traiter à la main`);
  }
  const same = editable.find((v) => v.versionString === marketingVersion);
  return { ok: true, reuseVersionId: same?.id ?? null };
}

export function checkNotes(text) {
  const notes = String(text).trim();
  if (!notes) return { ok: false, reason: 'release-notes/fr-FR.txt est vide' };
  if (notes.length > NOTES_MAX) return { ok: false, reason: `notes trop longues (${notes.length} > ${NOTES_MAX} caractères)` };
  return { ok: true, notes };
}

// ---------- lectures (aucune écriture) ----------

async function findApp(client) {
  const r = await client.get('/v1/apps', { 'filter[bundleId]': BUNDLE_ID });
  const app = r.data?.[0];
  if (!app) throw new Error(`aucune app App Store Connect pour ${BUNDLE_ID}`);
  return app;
}

// Lit TOUTES les pages : une liste tronquée ferait manquer la version en ligne et fausserait les contrôles.
export async function listVersions(client, appId, maxPages = 20) {
  const out = [];
  let r = await client.get(`/v1/apps/${appId}/appStoreVersions`, { 'filter[platform]': 'IOS', limit: 200 });
  for (let page = 1; ; page++) {
    out.push(...(r.data ?? []));
    const next = r.links?.next;
    if (!next) return out;
    if (page >= maxPages) throw new Error(`liste des versions trop longue (plus de ${maxPages} pages) : contrôle impossible`);
    r = await client.get(next);
  }
}

async function listBuilds(client, appId, limit) {
  const r = await client.get('/v1/builds', { 'filter[app]': appId, sort: '-uploadedDate', limit });
  return r.data ?? [];
}

export async function waitForBuild(client, appId, buildNumber, { sleepFn, log, tries = POLL_TRIES, ms = POLL_MS }) {
  for (let i = 1; i <= tries; i++) {
    const r = await client.get('/v1/builds', { 'filter[app]': appId, 'filter[version]': buildNumber, limit: 1 });
    const b = r.data?.[0];
    const state = b?.attributes.processingState;
    log(`  essai ${i}/${tries} : ${state ?? 'pas encore visible'}`);
    if (b && state === 'VALID') return b;
    if (state === 'FAILED' || state === 'INVALID') throw new Error(`traitement du build ${buildNumber} refusé par Apple : ${state}`);
    if (i < tries) await sleepFn(ms);
  }
  throw new Error(`build ${buildNumber} toujours en traitement après ${tries} essais : relancer plus tard, voir App Store Connect`);
}

export async function check(client, log = console.log) {
  const app = await findApp(client);
  log(`App : ${app.attributes?.name ?? '?'} (id ${app.id}, bundle ${BUNDLE_ID})`);
  const versions = await listVersions(client, app.id);
  for (const v of versions) {
    log(`Version ${v.attributes.versionString} : ${v.attributes.appStoreState}`);
  }
  const live = versions.find((v) => v.attributes.appStoreState === LIVE);
  log(live ? `Version en ligne sur l'App Store : ${live.attributes.versionString}` : "Aucune version en ligne sur l'App Store");
  const builds = await listBuilds(client, app.id, 3);
  for (const b of builds) {
    log(`Build ${b.attributes.version} : ${b.attributes.processingState} (reçu ${b.attributes.uploadedDate})`);
  }
  if (!builds.length) log('Aucun build reçu');
  log('Lecture seule : aucune version, note ni soumission créée.');
  const pf = await preflight({ client, log });
  log(`Préflight OK : version ${pf.plan.reuseVersionId ? 'en préparation réutilisée' : 'à créer'}, en ligne ${pf.live?.attributes.versionString ?? 'aucune'}, dernier build reçu ${pf.maxBuild ?? 'aucun'}, notes ${pf.notes.length} caractères.`);
  return { app, versions, builds };
}

// ---------- préflight (lecture seule, exécuté en premier par `publish`) ----------

// Ordre fixe : clé acceptée, aucune version en attente de revue, numéros, notes. Un échec lève une erreur
// avant toute archive ou envoi. Ne fait que des GET.
export async function preflight({ client, log = console.log, local, notesPath = NOTES_PATH } = {}) {
  let app;
  try {
    app = await findApp(client);
  } catch (err) {
    throw new Error(`clé refusée ou App Store Connect injoignable : ${err.message}. Rien n'a été envoyé.`);
  }
  const versions = await listVersions(client, app.id);
  const enAttente = versions.find((v) => EN_ATTENTE.includes(v.attributes.appStoreState));
  if (enAttente) {
    throw new Error(`version ${enAttente.attributes.versionString} en état ${enAttente.attributes.appStoreState} : attendre la fin de la revue Apple avant de publier. Rien n'a été envoyé.`);
  }
  const localVersions = local ?? readLocalVersions(readFileSync(PBXPROJ, 'utf8'));
  const live = versions.find((v) => v.attributes.appStoreState === LIVE);
  const builds = await listBuilds(client, app.id, 20);
  const maxBuild = builds.map((b) => b.attributes.version).reduce((acc, v) => (acc == null || compareVersions(v, acc) > 0 ? v : acc), null);
  const editable = versions
    .filter((v) => EDITABLE.includes(v.attributes.appStoreState))
    .map((v) => ({ id: v.id, versionString: v.attributes.versionString, appStoreState: v.attributes.appStoreState }));
  const plan = planControls({
    marketingVersion: localVersions.marketingVersion,
    buildNumber: localVersions.buildNumber,
    liveVersion: live?.attributes.versionString ?? null,
    maxBuild,
    editable,
  });
  if (!plan.ok) throw new Error(`contrôle des numéros refusé : ${plan.reason}. Rien n'a été envoyé.`);
  let notesText;
  try {
    notesText = readFileSync(notesPath, 'utf8');
  } catch {
    throw new Error(`notes absentes : ${notesPath}. Rien n'a été envoyé.`);
  }
  const notes = checkNotes(notesText);
  if (!notes.ok) throw new Error(`${notes.reason}. Rien n'a été envoyé.`);
  log(`Contrôles OK : version ${localVersions.marketingVersion} (build ${localVersions.buildNumber}), en ligne ${live?.attributes.versionString ?? 'aucune'}, dernier build reçu ${maxBuild ?? 'aucun'}.`);
  return { app, live, maxBuild, plan, local: localVersions, notes: notes.notes };
}

// ---------- publication (appelée seulement via `make release CONFIRMER=OK-APPLE`) ----------

function authArgs(cfg) {
  return ['-allowProvisioningUpdates', '-authenticationKeyPath', cfg.keyPath, '-authenticationKeyID', cfg.keyId, '-authenticationKeyIssuerID', cfg.issuerId];
}

function runXcode(args, label) {
  const r = spawnSync('xcodebuild', args, { cwd: ROOT, stdio: 'inherit' });
  if (r.status !== 0) throw new Error(`xcodebuild ${label} a échoué (code ${r.status ?? 'inconnu'})`);
}

export async function publish({
  client, cfg, confirm, log = console.log, sleepFn = (ms) => new Promise((r) => setTimeout(r, ms)),
  runXcodeFn = runXcode, localOverride, notesPath = NOTES_PATH,
}) {
  assertConfirmed(confirm);
  // Préflight d'abord : un refus ici = rien d'archivé, rien d'envoyé.
  const pf = await preflight({ client, log, local: localOverride, notesPath });
  const { plan, app } = pf;
  const local = pf.local;

  let step = 'archive';
  try {
    log('1/6 Archive Release (xcodebuild archive)…');
    runXcodeFn(['-scheme', SCHEME, '-configuration', 'Release', '-destination', 'generic/platform=iOS', '-derivedDataPath', BUILD_DIR, '-archivePath', ARCHIVE, ...authArgs(cfg), 'archive'], 'archive');

    step = 'envoi';
    log('2/6 Envoi du build vers App Store Connect (exportArchive, destination upload)…');
    runXcodeFn(['-exportArchive', '-archivePath', ARCHIVE, '-exportPath', EXPORT_DIR, '-exportOptionsPlist', EXPORT_PLIST, ...authArgs(cfg)], 'exportArchive');

    step = 'traitement';
    log(`3/6 Attente du traitement du build ${local.buildNumber} par Apple…`);
    const build = await waitForBuild(client, app.id, local.buildNumber, { sleepFn, log });

    step = 'version';
    log(`4/6 Version ${local.marketingVersion} : ${plan.reuseVersionId ? 'réutilisée (en préparation)' : 'création'}…`);
    const versionId = plan.reuseVersionId ?? (await client.post('/v1/appStoreVersions', {
      data: {
        type: 'appStoreVersions',
        attributes: { platform: 'IOS', versionString: local.marketingVersion },
        relationships: { app: { data: { type: 'apps', id: app.id } } },
      },
    })).data.id;

    step = 'nouveautés';
    log(`5/6 Nouveautés (${LOCALE}) depuis release-notes/fr-FR.txt, puis rattachement du build…`);
    const notes = pf.notes;
    const locs = await client.get(`/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations`, { limit: 50 });
    const loc = (locs.data ?? []).find((l) => l.attributes.locale === LOCALE);
    if (loc) {
      await client.patch(`/v1/appStoreVersionLocalizations/${loc.id}`, {
        data: { type: 'appStoreVersionLocalizations', id: loc.id, attributes: { whatsNew: notes } },
      });
    } else {
      await client.post('/v1/appStoreVersionLocalizations', {
        data: {
          type: 'appStoreVersionLocalizations',
          attributes: { locale: LOCALE, whatsNew: notes },
          relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } },
        },
      });
    }
    await client.patch(`/v1/appStoreVersions/${versionId}/relationships/build`, { data: { type: 'builds', id: build.id } });

    step = 'soumission';
    log('6/6 Soumission à la revue…');
    const rs = await client.post('/v1/reviewSubmissions', {
      data: { type: 'reviewSubmissions', attributes: { platform: 'IOS' }, relationships: { app: { data: { type: 'apps', id: app.id } } } },
    });
    await client.post('/v1/reviewSubmissionItems', {
      data: {
        type: 'reviewSubmissionItems',
        relationships: {
          reviewSubmission: { data: { type: 'reviewSubmissions', id: rs.data.id } },
          appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } },
        },
      },
    });
    await client.patch(`/v1/reviewSubmissions/${rs.data.id}`, {
      data: { type: 'reviewSubmissions', id: rs.data.id, attributes: { submitted: true } },
    });
    log(`Soumis à la revue : version ${local.marketingVersion}, build ${local.buildNumber}.`);
  } catch (err) {
    throw new Error(`arrêt à l'étape « ${step} » : ${err.message}. Un état partiel est possible : vérifier App Store Connect avant de relancer.`);
  }
}

// ---------- point d'entrée ----------

async function main(argv) {
  const [cmd, ...rest] = argv;
  if (cmd !== 'check' && cmd !== 'publish') {
    console.error('Usage : asc.mjs check | asc.mjs publish --confirm OK-APPLE');
    return 2;
  }
  const cfg = loadConfig();
  const client = makeClient({ keyId: cfg.keyId, issuerId: cfg.issuerId, privateKeyPem: loadKey(cfg.keyPath) });
  if (cmd === 'check') {
    await check(client);
    return 0;
  }
  const i = rest.indexOf('--confirm');
  await publish({ client, cfg, confirm: i >= 0 ? rest[i + 1] : undefined });
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2)).then(
    (code) => process.exit(code),
    (err) => {
      console.error(`ERREUR : ${err.message}`);
      process.exit(1);
    },
  );
}
