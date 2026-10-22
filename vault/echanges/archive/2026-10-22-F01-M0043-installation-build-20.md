---
date: 2026-10-22
tags: [installation, iphone, build-20]
session: F01
mandat: installation-build-20-iphone-malik
mandat_id: M0043
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0043
branche: feat/carte-localisation
niveau: N1
derniere_maj: 2026-10-22T20:51:03+0200
---

# F01 / M0043 — Installer le build 20 (tip de code 2e87c53, R035 GO) sur « iPhone de Malik »

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium. N1 : aucun code modifié, aucun commit.

## Décision du fondateur (22/10/2026 20:50)
« iPhone déverrouillé installe ».

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add --detach`, `git worktree remove`, `git worktree prune` et lectures). Aucun commit, push, merge. Jamais de `sleep`, de tâche de fond vivante à la sortie. **Aucune écriture Supabase. Aucun appel à Apple.** Aucun fichier du dépôt modifié hors `vault/echanges/F01.md` et `vault/runtime/`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `b397856576559524145231d437c62b9414a0c781`.
2. `.claude/worktrees/F01-M0043` absent.

## Travail
1. `git worktree add --detach .claude/worktrees/F01-M0043 b397856576559524145231d437c62b9414a0c781`.
2. `xcrun devicectl list devices` collé. « iPhone de Malik » `unavailable` → étape 5, dis-le.
3. Dans le worktree : `xcodebuild -scheme BoitesALivresNative -destination 'platform=iOS,id=00008101-001278EA36E9001E' -configuration Debug -derivedDataPath .build ONLY_ACTIVE_ARCH=YES CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates build` (fin collée).
4. `xcrun devicectl device install app --device 00008101-001278EA36E9001E .build/Build/Products/Debug-iphoneos/BoitesALivresNative.app` ; `xcrun devicectl device process launch --device 00008101-001278EA36E9001E com.malikkaraoui.boitesalivresapp` (verrouillé = le dire) ; `xcrun devicectl device info apps --device 00008101-001278EA36E9001E --bundle-id com.malikkaraoui.boitesalivresapp` → attendu `1.3.0 20`, collé. Install refusée (verrouillé, `CoreDeviceError 10003`) : le dire tel quel.
5. `git worktree remove --force .claude/worktrees/F01-M0043` puis `git worktree prune`.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN : `## Rapport M0043` dans ce fichier (2 lignes en français simple + preuves collées) → `vault/runtime/events.jsonl` + `state.json` (jamais committés) → pas de commit ni push → footer de statut (gabarit §4, première ligne `M0043` ; Commit/Push/Review/Merge = N/A ; TASK STATUS `INTEGRATED` si `info apps` montre `1.3.0 20`, sinon `BLOCKED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0043

Le build 20 (tip `b397856`, R035 GO) est installé et lancé sur « iPhone de Malik » ; l'app répond en `1.3.0 (20)`.
Aucun code modifié, aucun commit, aucun push ; le worktree temporaire est retiré.

**Garde** : `git fetch origin` puis `origin/feat/carte-localisation` = `b397856576559524145231d437c62b9414a0c781` (conforme) ; `.claude/worktrees/F01-M0043` absent avant création (conforme).

**Appareil** (`xcrun devicectl list devices`, ligne collée) :
```
iPhone de Malik                           00008101-001278EA36E9001E (UDID)                  available (paired)   iPhone 12 Pro (iPhone13,3)                   physical
```
Non `unavailable` : l'étape 5 (repli) ne s'applique pas.

**Worktree** : `git worktree add --detach .claude/worktrees/F01-M0043 b397856…` → `HEAD is now at b397856 docs(revues): R035 -- seuils localisation (M0042, #42), GO`.

**Build** (`xcodebuild … build`, log dans le scratchpad, fin collée) :
```
RegisterExecutionPolicyException …/BoitesALivresNative.app (in target 'BoitesALivresNative' from project 'BoitesALivresNative')
Validate …/BoitesALivresNative.app (in target 'BoitesALivresNative' from project 'BoitesALivresNative')
PruneExplicitPrecompiledModules …/.build/SDKExplicitPrecompiledModules

** BUILD SUCCEEDED **
```
Sortie `EXIT=0`.

**Installation** (`xcrun devicectl device install app`) :
```
App installed:
• bundleID: com.malikkaraoui.boitesalivresapp
• installationURL: file:///private/var/containers/Bundle/Application/2AA08A91-EC1A-428F-887C-45D1E902E55A/BoitesALivresNative.app/
INSTALL_EXIT=0
```

**Lancement** (`xcrun devicectl device process launch`) :
```
Launched application with com.malikkaraoui.boitesalivresapp bundle identifier.
LAUNCH_EXIT=0
```
L'appareil était déverrouillé (décision du fondateur : « iPhone déverrouillé installe ») ; aucune erreur `CoreDeviceError 10003`.

**Vérification de version** (`xcrun devicectl device info apps --bundle-id com.malikkaraoui.boitesalivresapp`) :
```
Name              Bundle Identifier                   Version   Bundle Version
---------------   ---------------------------------   -------   --------------
Boîtes à Livres   com.malikkaraoui.boitesalivresapp   1.3.0     20
INFO_EXIT=0
```
Attendu `1.3.0 20` : conforme.

**Nettoyage** : `git worktree remove --force .claude/worktrees/F01-M0043` (exit 0), `git worktree prune` (exit 0). `git worktree list` ne montre plus F01-M0043.

**Hors périmètre** : aucune écriture Supabase, aucun appel Apple, aucun fichier du dépôt modifié hors `vault/echanges/F01.md` et `vault/runtime/`.

```
M0043
Implementation      ✅
Tests               N/A
Commit              N/A
Branch push         N/A
Review              N/A
Merge main          N/A
Main push           N/A
TASK STATUS         INTEGRATED
PROJECT STATUS      NOT_INTEGRATED
```
