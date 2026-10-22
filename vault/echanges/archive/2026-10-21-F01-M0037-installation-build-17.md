---
date: 2026-10-21
tags: [installation, iphone, build-17]
session: F01
mandat: installation-build-17-iphone-malik
mandat_id: M0037
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0037
branche: feat/carte-localisation
niveau: N1
derniere_maj: 2026-10-21T19:09:52+0200
---

# F01 / M0037 — Installer le build 17 (branche feat/carte-localisation, revue R031 GO) sur « iPhone de Malik »

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium. N1 : aucun code modifié, aucun commit.

## Décision du fondateur (21/10/2026 19:09)
« build sur mon iphone je suis a la maison ».

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add --detach`, `git worktree remove`, `git worktree prune` et des lectures). Aucun commit, aucun push, aucun merge. Jamais de `sleep`, de tâche de fond vivante à la sortie. **Aucune écriture Supabase. Aucun appel à Apple** (ni release, ni archive, ni TestFlight). Aucun fichier du dépôt modifié hors `vault/echanges/F01.md` et `vault/runtime/`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `fa159395238d5ee2f09151912a7b5a40e7ce8d77`.
2. `.claude/worktrees/F01-M0037` absent.

## Travail
1. `git worktree add --detach .claude/worktrees/F01-M0037 fa159395238d5ee2f09151912a7b5a40e7ce8d77`.
2. `xcrun devicectl list devices` collé. « iPhone de Malik » `unavailable` → arrête-toi là (étape 5), dis-le au rapport.
3. Dans le worktree : `xcodebuild -scheme BoitesALivresNative -destination 'platform=iOS,id=00008101-001278EA36E9001E' -configuration Debug -derivedDataPath .build ONLY_ACTIVE_ARCH=YES CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates build` (fin collée).
4. `xcrun devicectl device install app --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A .build/Build/Products/Debug-iphoneos/BoitesALivresNative.app` ; `xcrun devicectl device process launch --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A com.malikkaraoui.boitesalivresapp` ; `xcrun devicectl device info apps --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A --bundle-id com.malikkaraoui.boitesalivresapp` → attendu `1.3.0 17`, collé.
5. `git worktree remove --force .claude/worktrees/F01-M0037` puis `git worktree prune`.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN : `## Rapport M0037` dans ce fichier (2 lignes en français simple + preuves collées) → `vault/runtime/events.jsonl` + `state.json` (jamais committés) → pas de commit ni push → footer de statut (gabarit §4, première ligne `M0037` ; Commit/Push/Review/Merge = N/A ; TASK STATUS `INTEGRATED` si `info apps` montre `1.3.0 17`, sinon `BLOCKED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0037

Build 17 (commit fa15939, branche feat/carte-localisation, R031 GO) compilé et installé sur « iPhone de Malik » : l'appareil était `connected`, pas `unavailable`. `info apps` affiche `1.3.0 17`, l'app s'est lancée.

Preuves :

```
git fetch origin ; git rev-parse origin/feat/carte-localisation
fa159395238d5ee2f09151912a7b5a40e7ce8d77
test -e .claude/worktrees/F01-M0037 -> ABSENT
git worktree add --detach .claude/worktrees/F01-M0037 fa159395238d5ee2f09151912a7b5a40e7ce8d77
HEAD is now at fa15939 docs(revues): R031 -- GO sur a9e4be71 (M0036, #34)
xcrun devicectl list devices -> « iPhone de Malik  00008101-001278EA36E9001E  connected  iPhone 12 Pro »
xcodebuild ... -allowProvisioningUpdates build  -> EXIT=0 ; ** BUILD SUCCEEDED **  (log : scratchpad/xcodebuild-M0037.log)
xcrun devicectl device install app ...  -> App installed (bundleID com.malikkaraoui.boitesalivresapp)  INSTALL_EXIT=0
xcrun devicectl device process launch ... -> Launched application  LAUNCH_EXIT=0
xcrun devicectl device info apps ... -> Boîtes à Livres  com.malikkaraoui.boitesalivresapp  1.3.0  17
git worktree remove --force .claude/worktrees/F01-M0037 ; git worktree prune -> ABSENT
```

Aucun fichier du dépôt modifié, aucun commit, aucun push, aucun appel Apple ni Supabase. Le worktree est retiré.

Scellé tests : N/A (aucun code modifié, aucun test lancé)
Contre-témoins : aucun

Implementation      N/A
Tests               N/A
Commit              N/A
Branch push         N/A
Review              N/A
Merge main          N/A
Main push           N/A
TASK STATUS         INTEGRATED
PROJECT STATUS      NOT_INTEGRATED
