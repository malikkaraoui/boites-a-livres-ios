---
date: 2026-10-21
tags: [installation, iphone, build-16, wifi]
session: F01
mandat: installation-iphone-laura-et-malik-bis
mandat_id: M0034
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0034
branche: main
niveau: N1
derniere_maj: 2026-10-21T16:32:33+0200
---

# F01 / M0034 — Installer le build 16 (1.3.0) sur « iPhone Laura » et « iPhone de Malik », en Wi-Fi

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question, les options et ton choix motivé, puis les rituels de fin. Demande d'autorisation d'outil : contourne par une commande plus simple ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium. N1 : aucun code modifié, aucun commit.

## Décision du fondateur (21/10/2026 16:31)
« iPhone de Laura et malik sont en wifi — envoi le dernier build rapidement ».

## Interdits permanents
**Aucun geste git en écriture à la racine du dépôt** : ni fetch, merge, commit, push, stash, reset, checkout, add. La racine est volontairement laissée telle quelle (`main` local `5f51d13` divergent, fichiers du harnais modifiés) : n'y touche pas, n'en parle qu'au rapport. Seuls gestes git permis : `git worktree add --detach` / `git worktree remove` / `git worktree prune` et lectures (`rev-parse`, `log`). Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`. `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`. **Aucune écriture Supabase. Aucune archive ni envoi App Store / TestFlight** (pas de `make release`, `make archive`, `altool`, `notarytool`). Aucun fichier du dépôt modifié hors `vault/echanges/F01.md` et `vault/runtime/`.

## Contexte
- `origin/main` = `739cbf67b877e09719a3ea8cb1b9861871c63d96` : code de l'app identique au build 16 (`995a6d6`, M0026). `project.yml` : 1.3.0 / 16.
- iPhone de Malik : UDID `00008101-001278EA36E9001E`, id devicectl `C3CFC878-6C8D-5B87-8B35-1CB108A4922A`. « iPhone Laura » : id à lire dans `xcrun devicectl list devices`. Les deux sont en Wi-Fi (appairage réseau) ; un appareil « unavailable » est injoignable.
- M0033 (archive `vault/echanges/archive/2026-10-20-F01-M0033-stop-garde-racine.md`) s'est arrêté sur la racine sale : c'est pour cela que ce mandat ne la touche pas.

## Garde (écart = STOP)
1. `git rev-parse origin/main` = `739cbf67b877e09719a3ea8cb1b9861871c63d96` (lecture seule, sans fetch).
2. `.claude/worktrees/F01-M0034` n'existe pas.

## Travail
1. `git worktree add --detach .claude/worktrees/F01-M0034 739cbf67b877e09719a3ea8cb1b9861871c63d96`. Tout le build se fait dedans.
2. `xcrun devicectl list devices` (sortie collée) : ids et UDID de « iPhone Laura » et « iPhone de Malik ».
3. **iPhone Laura**, dans le worktree : `xcodebuild -scheme BoitesALivresNative -destination 'platform=iOS,id=<UDID Laura>' -configuration Debug -derivedDataPath .build ONLY_ACTIVE_ARCH=YES CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates build` (fin collée) ; `xcrun devicectl device install app --device <id Laura> .build/Build/Products/Debug-iphoneos/BoitesALivresNative.app` ; `xcrun devicectl device process launch --device <id Laura> com.malikkaraoui.boitesalivresapp` ; `xcrun devicectl device info apps --device <id Laura> --bundle-id com.malikkaraoui.boitesalivresapp` → attendu `1.3.0 16`, collé. Échec (signature, appareil absent du profil, injoignable, verrouillé) : colle l'erreur exacte, passe à l'étape 4 (pas un STOP global).
4. **iPhone de Malik** : même chose avec `id=00008101-001278EA36E9001E` et `--device C3CFC878-6C8D-5B87-8B35-1CB108A4922A`. Vérification `1.3.0 16` collée. Échec : erreur exacte collée.
5. `git worktree remove --force .claude/worktrees/F01-M0034` puis `git worktree prune`.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0034` dans ce fichier (3 lignes en français simple : installé ou non sur chaque iPhone, raison exacte si non ; puis preuves collées) → `vault/runtime/events.jsonl` + `state.json` (jamais committés) → **pas de commit, pas de push** (interdit ci-dessus ; le rapport le dit) → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, `M0034` ; Commit/Push/Review/Merge = N/A ; TASK STATUS `INTEGRATED` si les deux installations sont prouvées par `info apps`, sinon `BLOCKED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0034

- **iPhone Laura** : installé, en 1.3.0 (16), lancé. Build Debug réussi, puis `devicectl install` et `info apps` sans erreur.
- **iPhone de Malik** : installé, en 1.3.0 (16), lancé. Même séquence, sans erreur.
- **Git** : aucun commit, aucun push, racine non touchée (`main` local reste `5f51d13`). Seul le worktree `.claude/worktrees/F01-M0034` a été créé puis retiré (`git worktree remove --force` + `prune`). Le worktree `F03-R003` existant n'a pas été touché.
- **Note** : `devicectl list devices` n'affiche que l'UDID de « iPhone Laura ». L'identifiant devicectl (`5F7DA86D-D802-5C1B-9180-2950A7DC1306`) a été lu en JSON (`--json-output`).

Preuves collées :

```
# Garde
origin/main=739cbf67b877e09719a3ea8cb1b9861871c63d96  (attendu identique)
worktree absent: OK

# Worktree
HEAD is now at 739cbf6 docs(revues): R029 -- GO sur 90c9d139f98ad06a36b2ff6bb0d2284f694e7e52 (M0032)

# Laura (UDID 00008101-001A7C1E0C42001E, devicectl 5F7DA86D-D802-5C1B-9180-2950A7DC1306)
xcodebuild ... build  -> ** BUILD SUCCEEDED ** (exit 0)
devicectl device install app  -> App installed: com.malikkaraoui.boitesalivresapp (install=0)
devicectl device process launch -> Launched application ... (launch=0)
devicectl device info apps -> Boîtes à Livres | com.malikkaraoui.boitesalivresapp | 1.3.0 | 16

# Malik (UDID 00008101-001278EA36E9001E, devicectl C3CFC878-6C8D-5B87-8B35-1CB108A4922A)
xcodebuild ... build  -> ** BUILD SUCCEEDED ** (exit 0)
devicectl device install app  -> App installed: com.malikkaraoui.boitesalivresapp (install=0)
devicectl device process launch -> Launched application ... (launch=0)
devicectl device info apps -> Boîtes à Livres | com.malikkaraoui.boitesalivresapp | 1.3.0 | 16

# Nettoyage
git worktree remove --force .claude/worktrees/F01-M0034  (remove=0)
git worktree prune  (prune=0)
```

Mandat exécuté en N1 : aucun code modifié, aucun commit, aucune archive ni envoi App Store / TestFlight.

M0034
Implementation      ✅
Tests               N/A
Commit              N/A
Branch push         N/A
Review              N/A
Merge main          N/A
Main push           N/A
TASK STATUS         INTEGRATED
PROJECT STATUS      NOT_INTEGRATED
