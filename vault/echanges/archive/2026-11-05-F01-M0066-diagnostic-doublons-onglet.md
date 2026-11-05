---
date: 2026-11-05
tags: [reglages, diagnostic, alerte-proximite, doublons, onglet, build-33, merge]
session: F01
mandat: diagnostic-cache-doublons-onglet-reglages
mandat_id: M0066
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0066
branche: fix/diagnostic-doublons-onglet
niveau: N3
derniere_maj: 2026-11-05T16:02:02+0100
---

# F01 / M0066 — Diagnostic des alertes caché dans les versions publiées ; journal/surveillance en double corrigés ; re-toucher « Réglages » ramène à la racine ; build 33 ; fusion ; installation iPhone

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Arbitrage nécessaire = **STOP propre** (question, options, choix motivé au rapport, puis rituels de fin). **Va jusqu'au bout.**

Modèle : Haiku 5.5 medium (doublage compris). **N3** (`project.yml`/`project.pbxproj`).

## Demandes du fondateur (verbatim, datées — ne pas re-débattre)
- 05/11 15:59 (capture « Diagnostic des alertes », iPhone build 32) : « penses a supprimé le diagnostique alerte, les utilisateurs ne doivent pas le voir ». Orchestrateur 15:59 : caché dans les versions publiées (Release : App Store/TestFlight), **gardé dans les builds de test Debug** installés sur l'iPhone du fondateur (pour enquêter).
- 05/11 16:00 : « quand je suis dans cette fameuse "diagnostic des alertes" j'aimerai pouvoir revenir en arriere (réglage) sans devoir cliquer sur réglage en haut a gauche mais directement depuis la bar de navigation en bas a gauche "Réglages" ».
- 05/11 16:01 : « on garde les regles actuelle » → la règle 7 km/h / vitesse inconnue = pas de notification **NE CHANGE PAS**.
- Défaut vu sur la capture (16:04:55) : chaque ligne du journal en **6 exemplaires à la même seconde** (« dans le rayon de la boîte 99388 (état au démarrage) » + « vitesse inconnue, pas de notification »), « régions enregistrées : 20 » **2 fois** → surveillance/traitement lancés plusieurs fois.

## Contexte lu par l'orchestrateur (`origin/main` `0cccbf2`)
- `App/SettingsView.swift:52` `NavigationStack` (sans chemin lié) ; `:255` `NavigationLink("Diagnostic des alertes") { ProximityDiagnosticView() }` ; `:612-630` `ProximityDiagnosticView`.
- `App/ContentView.swift` `tabButton` : re-toucher l'onglet actif vide `mapPath` (0) et `listPath` (1), **rien pour Réglages (2)**.
- `Services/ProximityAlertService.swift:43` `startMonitoringSignificantLocationChanges()`, `:80` journal « régions enregistrées », `:86` `startMonitoring(for:)`, `:92-106` règle vitesse + journal « vitesse inconnue ».

## Règles
1. **Diagnostic** : la ligne « Diagnostic des alertes » (et l'écran) n'existe que dans la configuration **Debug** (`#if DEBUG`) ; en Release, ni ligne, ni écran atteignable. Le journal interne peut continuer d'écrire (sans coût visible). Prouver par le build Release (grep de la chaîne absente de l'UI compilée ou test) et Debug (présente).
2. **Doublons** : trouver pourquoi l'enregistrement des régions et le traitement « état au démarrage » s'exécutent plusieurs fois (appels répétés d'activation au retour au premier plan, plusieurs délégués/instances, `didDetermineState` × régions déjà surveillées, etc.). Cause prouvée fichier:ligne. Corriger à la source : un seul enregistrement par changement réel, un seul traitement par événement et par boîte ; le journal n'écrit qu'une ligne par événement. **La règle de vitesse ne change pas.** Test unitaire si une fonction pure s'y prête.
3. **Onglet Réglages** : re-toucher « Réglages » quand il est actif ramène à la racine de Réglages (comme Carte et Liste) : `NavigationStack(path:)` lié à un `settingsPath` dans `ContentView`, vidé au re-toucher et quand on quitte l'onglet (comme `mapPath`/`listPath`).
4. Ne touche pas `Services/LocationService.swift`, `NotificationService.swift`, `App/Constants.swift`, `AppDelegate.swift` sauf si la cause des doublons y est : alors le dire et le justifier au rapport (N3 couvre). Aucun payload/endpoint/base changé.

## Version 33
`project.yml` `CURRENT_PROJECT_VERSION: 33` (MARKETING 1.3.0 inchangé), `project.pbxproj` aligné, `CHANGELOG.md` « Build 33 : diagnostic des alertes réservé aux builds de test ; alertes de proximité sans traitement en double ; re-toucher Réglages ramène à la racine » ; `release-notes/fr-FR.txt` et `en-US.txt` : « build 32 » → « build 33 » seulement.

## Interdits permanents
Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase, de `stash`, de `reset --hard`, de `checkout -- .`. `git add` ciblé. **Aucune écriture Supabase. Aucun appel à Apple** (« OK Apple » requis). Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`. Refus d'un hook : STOP.

## Garde (écart = STOP)
`git fetch origin --prune` ; `origin/main` contient `0cccbf2` et, après lui, seulement des chemins `vault/`.

## Mission 0 — scope git strict
Scratch détaché sur `origin/main` : commit ciblé de `vault/echanges/archive/2026-11-05-F01-M0064-apercu-fiche-ios.md` et `vault/echanges/archive/2026-11-05-F03-M0065-install-racine.md` s'ils ne sont pas suivis, push `HEAD:main`, `ls-remote` collé.

## Travail
1. `git worktree add -b fix/diagnostic-doublons-onglet .claude/worktrees/F01-M0066 origin/main`. Issue `gh issue create` ; numéro cité dans les commits.
2. Règles 1-4 ; version 33.
3. Tests : Build **Release** `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` et build **Debug** (fins collées) ; `node --test scripts/release/asc.test.mjs` vert. Simulateur : essaie (journal du diagnostic sans doublon après un démarrage dans un rayon simulé) ; s'il ne démarre pas, le dire, ne le répare pas → checklist fondateur.
4. Commits ciblés, **push de la branche AVANT relecture**, `ls-remote` collé. Tip = `T`.
5. **Doublage N3 `R055`** (relu dans `state.json`) : sous-agent FRAIS (Haiku), lecture seule sur `T` : règles 1-4 fichier:ligne, cause des doublons prouvée et corrigée à la source, règle de vitesse intacte, `#if DEBUG` correct, `settingsPath` vidé, version 33, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base $(git merge-base origin/main T)` collé. Rapport `vault/revues/2026-11-05-R055-diagnostic-doublons-onglet.md` (frontmatter fermé : `verdict:`, `tip:` sha 40, `niveau: N3`). RESERVE → correctif → `R055b` ; loi des deux patchs.
6. Si GO : fusion (gabarit §9 mode direct, `.claude/skills/orchestration-bureau/references/gabarits.md` lu en entier), push, `ls-remote` ; branche et worktrees retirés. **Puis racine** : `git -C <racine> merge --ff-only origin/main` (les `vault/echanges/Fxx.md` sont désormais ignorés) ; `rev-parse HEAD origin/main` collé (même SHA).
7. **Installation iPhone** (Wi-Fi, build Debug, `devicectl`, id `00008101-001278EA36E9001E`, méthode `vault/echanges/archive/F02-M0059.md` étape 7) → `device info apps` → `1.3.0 33`. Injoignable → le dire.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`).

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : `## Rapport M0066` (5 lignes max en français simple ; cause des doublons en une phrase ; ce qui n'a PAS été vu ; checklist fondateur : ouvrir Réglages en build de test → diagnostic présent, re-toucher Réglages → racine, journal sans doublon après un démarrage près d'une boîte) → `vault/reprise/F01.md` → `events.jsonl` + `state.json` (non committés ; `windows.F01`, `last_event`, `updated_at`, `next_revue_id`) → commit vault ciblé via scratch, push, `ls-remote`, ff de la racine → **footer gabarit §4 OBLIGATOIRE en toute dernière ligne (première ligne `M0066`)** → `statut: reponse-disponible` EN DERNIER GESTE.

## Rapport M0066

- **Fusionné** : `main` = `3855f17` (ff de `ce08c6d` = revue R055 GO, merge `13e4a7d`). Branche et worktrees retirés.
- **Cause des doublons** : `didUpdateLocations` réenregistrait les 20 régions à chaque position ; chaque réponse « dedans » lançait un traitement journalisé avant son garde. Corrigé (`04a68cb`).
- **Non installé** : signature refusée (`ApplicationVerificationFailed`) ; le provisioning passe par Apple (« OK Apple » requis). Téléphone toujours en `1.3.0 32`.
- **Non vu** : double journal non reproduit en simulateur ; aucun test UI ; comportement CoreLocation sur appareil. Remarques non bloquantes : #74.

**Checklist fondateur** (après OK Apple et installation de la build 33) :
1. Réglages, build de test : « Diagnostic des alertes » présent.
2. Build App Store/TestFlight : aucune ligne « Diagnostic des alertes ».
3. Ouvrir Diagnostic, puis re-toucher « Réglages » en bas : retour à la racine de Réglages.
4. Démarrer l'app près d'une boîte : une seule ligne « dans le rayon » par événement, pas de six lignes identiques.

Mxxxx
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         INTEGRATED
PROJECT STATUS      INTEGRATED
