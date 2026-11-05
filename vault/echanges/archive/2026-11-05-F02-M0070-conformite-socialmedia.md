---
date: 2026-11-05
tags: [publication, app-store, ok-apple, export-compliance, soumission]
session: F02
mandat: soumission-1.4.0-conformite-export
mandat_id: M0070
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-opus-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F02.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F02-M0070
branche: fix/conformite-export-plist
niveau: N3
derniere_maj: 2026-11-05T18:15:33+0100
---

# F02 / M0070 — **OK APPLE** : soumettre à la revue la 1.4.0 (build 34) déjà préparée chez Apple ; conformité à l'exportation ; clé Info.plist pour les prochains builds

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Arbitrage = **STOP propre** (question, options, choix motivé au rapport). **Va jusqu'au bout.**

Modèle : Opus 5.5 medium (proposé par l'orchestrateur 18:13, accepté « Envoi la sauce pour la soumission Apple ! » 18:14).

## Feu vert du fondateur (verbatim)
- 05/11 17:54 : « OK APPLE — soumet a apple cette nouvelle version ». 18:13 : texte des nouveautés « parfait ». 18:14 : « Envoi la sauce pour la soumission Apple ! » ; « Y'avait encore cette demande d'algorithme de chiffrage ou non ».

## État laissé par M0069 (`vault/reprise/F01.md`, commit `303bc12`)
- 1.3.0 (28) en ligne ; **1.4.0** créée, `PREPARE_FOR_SUBMISSION` ; **build 34** envoyé, VALID, rattaché ; notes fr-FR (996 car.) et en-US (834 car.) posées.
- Soumission : `POST /v1/reviewSubmissionItems` → **HTTP 409** « appStoreVersions … is not in valid state ». Une `reviewSubmission` **72c9d21a…** `READY_FOR_REVIEW` reste ouverte.
- `make release` ne peut plus être relancé tel quel (préflight : build 34 « non supérieur au dernier reçu »). Outil API : `scripts/release/asc.mjs`, clé `~/.appstoreconnect/config.env` (JAMAIS affichée).

## Hypothèse principale de l'orchestrateur (à vérifier, pas à croire)
- `Info.plist` sur `origin/main` n'a **pas** `ITSAppUsesNonExemptEncryption` (grep vide) → chaque build reçu arrive en « Conformité à l'exportation manquante » et ne peut pas être soumis tant que la question n'est pas répondue. Le fondateur s'en souvient (« demande d'algorithme de chiffrage »).
- Chiffrement réel de l'app (lu à 18:16) : HTTPS du système uniquement + `CryptoKit` **SHA256 seulement**, pour nommer des fichiers de cache (`Services/ImageCacheService.swift:81`, `Services/LocalCacheService.swift:75`). Hachage ≠ chiffrement de données → **exempt** : réponse attendue « n'utilise pas de chiffrement non exempté » (`usesNonExemptEncryption = false`). Vérifie toi-même qu'aucun autre usage (grep `CryptoKit|CommonCrypto|CCCrypt|SecKey|AES|ChaCha` sur tout le code iOS) ne contredit ; si un vrai chiffrement de données apparaît : STOP.

## Étape 1 — diagnostic (lecture seule, API)
GET collés (sans jeton) : le build 34 (`processingState`, `usesNonExemptEncryption`, `buildAudienceType`), la version 1.4.0 (`appStoreState`, build rattaché), la `reviewSubmission` 72c9d21a (`state`, items), et toute autre reviewSubmission ouverte de l'app. Conclure la cause du 409 preuve à l'appui.

## Étape 2 — corriger et soumettre (OK Apple)
1. Si `usesNonExemptEncryption` est nul sur le build 34 : `PATCH /v1/builds/{id}` → `usesNonExemptEncryption: false` ; GET de contrôle collé.
2. Lever toute autre cause trouvée à l'étape 1 si elle se règle par l'API sans décision humaine (sinon STOP avec la liste exacte de ce qu'Apple réclame et où cliquer dans App Store Connect).
3. Soumettre : utiliser la `reviewSubmission` ouverte (ajout de la version 1.4.0 comme item si absente, puis `submitted: true`), ou l'annuler proprement et en créer une neuve — dire laquelle et pourquoi. **Ne jamais toucher à la 1.3.0 en ligne.**
4. Contrôle final : GET version 1.4.0 → `WAITING_FOR_REVIEW` (collé) ; notes fr-FR et en-US relues (GET) inchangées.
5. Petit script éventuel : à côté de `asc.mjs`, sans secret ; s'il mérite d'être gardé, il suit l'étape 3 (branche + relecture).

## Étape 3 — pour les prochains builds (n'affecte pas la soumission en cours)
Branche `fix/conformite-export-plist` depuis `origin/main` : `ITSAppUsesNonExemptEncryption = NO` dans l'Info.plist (via `project.yml` `info.properties` si c'est là qu'il est généré, sinon `Info.plist`), et, si utile, prise en charge de la conformité dans `asc.mjs` + test dans `asc.test.mjs`. Build Release générique vert, `node --test scripts/release/asc.test.mjs` vert. Commit, push. **Relecture N3 `R057`** (relu dans `state.json`, sous-agent FRAIS) → rapport `vault/revues/2026-11-05-R057-conformite-export.md` (`verdict:`, `tip:` sha 40, `niveau: N3`) → GO → fusion (gabarit §9 mode direct) → ff racine (`rev-parse HEAD origin/main` collé). Pas de nouveau numéro de build (aucun envoi).

## Interdits
Jamais afficher la clé `.p8`, un jeton, ni `config.env`. Aucune écriture Supabase. Ne JAMAIS retirer de la vente ni modifier la 1.3.0. Ne pas relancer `make release`. Une erreur Apple inattendue = arrêt + message exact + étape. Jamais de `sleep` (sauf attente bornée d'un état Apple : au plus 10 sondages espacés de 30 s, dits au rapport), de tâche de fond vivante, de `--no-verify`, de `push --force`, de rebase, de `stash`, de `reset --hard`. Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, n'appelle l'API Apple en écriture, ne modifie `vault/runtime/` ni `vault/reprise/` ; (3) rapport vérifié ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- Mission 0 : commit ciblé via scratch sur `origin/main` des archives `2026-11-05-F02-M0068-installation-33-ok.md` et `2026-11-05-F01-M0069-publication-1.4.0-409.md` (si non suivies).
- FIN : `## Rapport M0070` **dans ce fichier** (4 lignes en français simple en tête : cause du 409, 1.4.0 soumise oui/non + état Apple lu, chiffrement répondu comment, Info.plist corrigé oui/non) → `vault/reprise/F02.md` → `events.jsonl` + `state.json` (`windows.F02`, `last_event`, `updated_at`, `next_revue_id` ; non committés) → commit vault via scratch, push, `ls-remote`, ff racine → **footer gabarit §4 en toute dernière ligne, première ligne EXACTEMENT `M0070`** → `statut: reponse-disponible` EN DERNIER GESTE.

## Rapport M0070

- **Cause du 409** : ce n'était PAS la conformité à l'exportation. Apple refuse la 1.4.0 parce qu'une **nouvelle question de la classification par âge, « Réseaux sociaux » (`socialMedia`), n'a pas de réponse**. Preuve : corps complet du 409 ci-dessous.
- **1.4.0 soumise : NON (STOP)**. État Apple lu à 18:2x : 1.4.0 `PREPARE_FOR_SUBMISSION`, 1.3.0 `READY_FOR_SALE` (non touchée), soumission `72c9d21a` `READY_FOR_REVIEW` vide. Répondre à cette question est une déclaration du fondateur à Apple : je ne la fais pas à sa place.
- **Chiffrement** : déjà répondu chez Apple, build 34 `usesNonExemptEncryption=false` (lu, aucun PATCH fait). Vérifié dans le code : seulement `SHA256` pour nommer des fichiers de cache, aucune dépendance externe → exempté.
- **Info.plist corrigé : OUI**, `ITSAppUsesNonExemptEncryption = NO`, fusionné sur `main` (`405209f`) après relecture R057 GO. Vaut pour les prochains builds.

### Ce que le fondateur doit faire (2 minutes)
App Store Connect → Boîtes à Livres → **Informations sur l'app** (menu de gauche, section Général) → **Classification par âge** → Modifier → question **« Réseaux sociaux » / « Social media »** → répondre (choix que j'aurais fait : **Non** — l'app est une carte de boîtes à livres, pas un réseau social) → Enregistrer. Puis soit cliquer « Ajouter pour vérification » / « Soumettre » sur la 1.4.0, soit me relancer : la soumission se fait alors en 2 appels API (item dans `72c9d21a`, puis `submitted: true`).
Options vues : (a) Non [recommandé] ; (b) Oui → l'âge minimal pourrait monter et Apple exige alors `socialMediaAgeRestricted`. Point à regarder au passage : `userGeneratedContent` est déclaré `false`, alors que l'app laisse les utilisateurs poster des avis et des photos — à confirmer par le fondateur (règle Apple 1.2 sur les contenus d'utilisateurs).

### Étape 1 — diagnostic (GET, sans jeton)
```
VERSION c043b93c… 1.4.0 PREPARE_FOR_SUBMISSION build= 34
VERSION 00135253… 1.3.0 READY_FOR_SALE build= 28
BUILD b8303dd6… 34 VALID usesNonExemptEncryption= false audience= APP_STORE_ELIGIBLE expired= false
RS 72c9d21a-0799-4abe-ae30-dc4f8541ce82 READY_FOR_REVIEW items= []
RS 8abee82a… COMPLETE (1.3.0 APPROVED) ; 9ca92355, 7a54278e, 82ea8125 COMPLETE — aucune autre soumission ouverte
Localisations 1.4.0 : fr-FR (whatsNew 996, captures 6.5/6.7/iPad), en-US (834, idem) ; review detail rempli ; ageRating appInfo 715b7374 : socialMedia null
```
POST `/v1/reviewSubmissionItems` (soumission 72c9d21a + version 1.4.0) rejoué une fois pour lire le corps complet :
```
HTTP 409 STATE_ERROR.ENTITY_STATE_INVALID "appStoreVersions with id 'c043b93c-…' is not in valid state."
associatedErrors: /v1/ageRatingDeclarations/c043b93c-… : ENTITY_ERROR.ATTRIBUTE.REQUIRED
  "You must provide a value for the attribute 'socialMedia' with this request" (/data/attributes/socialMedia)
```
L'ancien `asc.mjs` n'affichait que title + detail, d'où la cause cachée en M0069.

### Étape 2 — contrôles finaux (GET)
`1.4.0 PREPARE_FOR_SUBMISSION` · `1.3.0 READY_FOR_SALE` · `RS 72c9d21a READY_FOR_REVIEW` · notes `fr-FR 996 car. = release-notes/fr-FR.txt`, `en-US 834 car. = release-notes/en-US.txt` (inchangées). Aucun PATCH/POST réussi chez Apple ; aucune attente, aucun `sleep`.

### Étape 3 — Info.plist + asc.mjs
- Commit `05f36b1` (branche `fix/conformite-export-plist`) : `Info.plist` + `describeErrors` dans `asc.mjs` (cite `meta.associatedErrors`) + test.
- `node --test scripts/release/asc.test.mjs` : 18/18 ; témoin rouge sur `c07d4f0` : `does not provide an export named 'describeErrors'`. Build Release générique : `** BUILD SUCCEEDED **`, PlistBuddy sur l'app produite : `false`. Aucun nouveau numéro de build.
- Relecture N3 **R057 GO** (sous-agent frais), `vault/revues/2026-11-05-R057-conformite-export.md`, `tip: 05f36b1c9c741289ca7dd024b8a5e47cef86e3c1`. Remarques → issue #75.
- Fusion : merge `b243eef`, rapport `405209f` ; tests 18/18 sur le résultat. `git ls-remote origin refs/heads/main` → `405209fe29ddd91dd07df2e8292cdd07d6f5b312`. Branche supprimée (locale + distante), worktrees F02-* retirés.
- Mission 0 : `c07d4f0` (archives M0068, M0069) poussé.

Scellé tests : sans objet (`scripts/verifier-rendu.mjs` absent du dépôt)
Contre-témoins : aucun
- Vault : reprise `68ed807` poussée, `git ls-remote origin refs/heads/main` → `68ed80794f94654518646303758317c262b80056`, racine ff. Registres `state.json` (next_revue_id R058) et `events.jsonl` écrits, non committés.

```
M0070
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         BLOCKED
PROJECT STATUS      INTEGRATED
```
