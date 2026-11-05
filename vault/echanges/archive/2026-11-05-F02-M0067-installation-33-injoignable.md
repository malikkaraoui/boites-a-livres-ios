---
date: 2026-11-05
tags: [installation, iphone, build-33]
session: F02
mandat: installation-iphone-build-33
mandat_id: M0067
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F02.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F02-M0067
branche: main
niveau: N1
derniere_maj: 2026-11-05T16:25:52+0100
---

# F02 / M0067 — Installer la build 33 (`main`) sur l'iPhone de Malik en Wi-Fi — AUCUN changement de code

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Arbitrage = STOP propre au rapport. Mandat COURT (< 15 min).

## Contexte
- Fondateur 05/11 16:17 : « j'attends la version 33 ». M0066 a fusionné la 33 (`origin/main` `3855f17`, `CURRENT_PROJECT_VERSION: 33`) mais **n'a pas installé** : `ApplicationVerificationFailed`, et il a cru à tort qu'il fallait « OK Apple ».
- **Précision de l'orchestrateur** : « OK Apple » concerne UNIQUEMENT l'App Store et TestFlight (archive, envoi). La signature de **développement** automatique (`-allowProvisioningUpdates`) pour installer un build Debug sur l'iPhone du fondateur est AUTORISÉE : c'est la méthode de M0059 (build 29), M0060 (30), M0062 (31), M0063 (31), M0064/M0065 (32), toutes réussies aujourd'hui et le 25/10.

## Garde
`git fetch origin --prune` ; `origin/main` contient `3855f17` ; `project.yml` : `CURRENT_PROJECT_VERSION: 33`. Sinon STOP.

## Travail
1. Worktree détaché temporaire `.claude/worktrees/F02-M0067` sur `origin/main`.
2. `xcrun devicectl list devices` + `device info apps --device 00008101-001278EA36E9001E` (ligne Boîtes à Livres) collés.
3. Build **Debug** `-scheme BoitesALivresNative -configuration Debug -destination 'platform=iOS,id=00008101-001278EA36E9001E' -allowProvisioningUpdates` (signature automatique, comme `vault/echanges/archive/F02-M0059.md` étape 7) ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E <app>` ; `device info apps` collé → attendu `1.3.0 33`.
4. Si `ApplicationVerificationFailed` revient : coller l'erreur COMPLÈTE ; vérifier `codesign -dv --verbose=4 <app>` (équipe, profil) et `security find-identity -v -p codesigning` (collés, sans secret) ; comparer avec ce que M0065 a fait à 14:15 (`vault/echanges/archive/2026-11-05-F03-M0065-install-racine.md`, si présent, ou `git log -p -- vault/reprise/F03.md`). Un second essai après `rm -rf` GARDÉ du dossier DerivedData de ce worktree uniquement. Toujours en échec → rendre avec le diagnostic, sans boucle.
5. Worktree retiré.

## Interdits
Aucun changement de code, aucun commit hors `vault/`, **aucune archive App Store ni envoi TestFlight**. Jamais de `sleep`, de tâche de fond vivante, de `--no-verify`, de `stash`, de `reset --hard`. Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : `## Rapport M0067` (3 lignes en français simple : installé oui/non, version avant/après) → `vault/reprise/F02.md` → `events.jsonl` + `state.json` (`windows.F02`, `last_event`, `updated_at` ; non committés) → commit vault ciblé via scratch sur `origin/main` (dont les archives `2026-11-05-F01-M0066-diagnostic-doublons-onglet.md` et `2026-11-05-F02-M0063-installation-31-bis.md` si non suivies), push, `ls-remote`, ff de la racine (`rev-parse HEAD origin/main` collé) → **footer gabarit §4 en toute dernière ligne, première ligne EXACTEMENT `M0067`** → `statut: reponse-disponible` EN DERNIER GESTE.

## Rapport M0067

- Installé : **non**. L'iPhone de Malik est injoignable (`unavailable` dans `devicectl`, absent des destinations `xcodebuild`) ; l'installation n'a pas été tentée. Aucune installation sur l'iPhone de Laura.
- Version avant : inconnue (appareil injoignable ; dernière installation connue 32). Version après : 33 non installée.
- Action pour Malik : déverrouiller l'iPhone, vérifier le Wi-Fi local, puis relancer M0067. Aucun changement de code, aucune archive App Store, aucun envoi TestFlight.
M0067
Implementation      N/A
Tests               N/A
Commit              ✅ 87e3f86
Branch push         ✅ main (ls-remote 87e3f86)
Review              N/A
Merge main          N/A
Main push           ✅ 87e3f86
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
