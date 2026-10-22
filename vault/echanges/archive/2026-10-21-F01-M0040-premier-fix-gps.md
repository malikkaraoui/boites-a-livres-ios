---
date: 2026-10-21
tags: [ajout-boite, carte, gps, build-18]
session: F01
mandat: ajout-boite-premier-fix-gps-reconception
mandat_id: M0040
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0040
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-21T20:08:53+0200
---

# F01 / M0040 — Premier fix GPS : nouveau mécanisme par horodatage (reconception, loi des deux patchs) ; doublage N3 R033 ; installation build 18

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3**.

## Contexte
M0039 (archive `vault/echanges/archive/2026-10-21-F01-M0039-carte-centree-nogo.md`) et R032 (`vault/revues/2026-10-21-R032-ajout-boite.md`, sur la branche) : NO-GO. Une position en cache (`Services/LocationService.swift:40`, `manager.location` sans contrôle d'âge) et le rejeu de `@Published` à l'abonnement (`App/AddBoxView.swift:46`, `.onReceive(locationService.$currentLocation.compactMap { $0 }) { vm.applyFirstFix($0) }`) consomment le « premier fix » : la position réelle n'est jamais appliquée. Deux correctifs (`3759e82`, `34f3668`) sur cette classe : **on change de mécanisme, on ne repatche pas**.

## Décision de l'orchestrateur (arbitrage demandé par R032) — mécanisme imposé
Le « premier fix » se juge à **l'horodatage de la position**, pas à l'ordre d'arrivée :
1. À chaque ouverture de l'étape position (première ouverture ET retour par « Replacer »), le VM note `positionStepOpenedAt = Date()` et remet `waitingFreshFix = true`.
2. Une position n'est **fraîche** que si `location.timestamp >= positionStepOpenedAt` ET `location.horizontalAccuracy >= 0`. Toute position plus ancienne (cache, rejeu `@Published`) est **ignorée** pour le centrage automatique. Fonction pure testable : `LocationRules.isFresh(timestamp:openedAt:accuracy:) -> Bool`.
3. Première position fraîche reçue alors que `waitingFreshFix` : caméra centrée dessus (≈ 300 m) ; le **repère** n'y est placé que si l'utilisateur n'a encore jamais touché la carte (première ouverture) ; au retour « Replacer », le repère reste où il était. Puis `waitingFreshFix = false`.
4. En attendant la position fraîche, la caméra peut utiliser le cache s'il existe (jamais la vue « France entière » si une position, même ancienne, est connue).
5. Ne modifie pas `LocationService` (zone critique partagée) sauf si c'est indispensable pour obtenir des mises à jour fraîches (ex. démarrage des mises à jour à l'ouverture de l'écran) ; dans ce cas, changement minimal, justifié au rapport, aucun effet sur l'alerte de proximité.
6. Supprime le mécanisme précédent (`autoCentered`/`applyFirstFix` tel quel) : pas de double logique.

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucun changement de payload/endpoint/champ.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `3b6e5b3d670a27a61aae07db0dfd7744e6f872f3`.
2. `.claude/worktrees/F01-M0040` absent ; aucun autre worktree sur `feat/carte-localisation`.

## Mise en place
`git worktree add .claude/worktrees/F01-M0040 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `3b6e5b3…` collé (sinon STOP).

## Travail
1. Implémente le mécanisme ci-dessus (`App/AddBoxView.swift`, `ViewModels/AddBoxViewModel.swift`, `Models/BookBox.swift` pour `isFresh`). Le reste de M0038/M0039 inchangé (marqueur posé au toucher, glisser la carte ne déplace pas le repère, note, un saut de ligne, précision 50 m).
2. **Témoin rouge d'abord** : test de logique pure (`swiftc` hors dépôt, vrai `Models/BookBox.swift` + la logique de décision extraite en fonction pure, ex. `LocationRules.firstFixAction(...)`) qui reproduit la réserve R032 sur `34f3668` (cache ancien puis fix live → le fix live doit être appliqué) : **rouge** sur `34f3668`, **vert** sur le nouveau tip. Cas : cache ancien seul (ignoré), cache ancien puis fix live (appliqué), fix live sans cache (appliqué), deuxième fix live (ignoré), retour « Replacer » (caméra recentrée, repère conservé), précision négative (ignorée). Plus les cas note/précision de M0038.
3. Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert.
4. Commit `fix(ajout-boite): premier fix GPS jugé à l'horodatage (#38)`, push + `git ls-remote` collé. Tip = `T`.
5. **Doublage N3 `R033`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur **tout** le diff `fa159395238d5ee2f09151912a7b5a40e7ce8d77..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie fichier:ligne la réserve R032 levée (rejoue le témoin rouge/vert), puis tous les points de M0038/M0039 (note au-dessus du clavier, hauteur fixe + défilement, un saut de ligne, précision 50 m, carte centrée, repère conservé, toucher = placer, pas de vue France, aucun changement de payload, alerte de proximité non affectée, build 18 cohérent), budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base fa159395238d5ee2f09151912a7b5a40e7ce8d77` collé. Rapport `vault/revues/2026-10-21-R033-premier-fix-gps.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. **Réserve prouvée par test rouge → STOP** (pas de nouveau correctif dans ce mandat). Remarques → issues. Rapport committé sur la branche + push + `ls-remote` collé.
6. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A …` ; lancement ; `device info apps` → `1.3.0 18` collé. `unavailable` → le dire (pas un STOP).
7. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0040` dans ce fichier (5 lignes max en français simple ; preuves dont témoin rouge/vert ; 4 gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0040` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0040

En français simple : le premier fix GPS est maintenant jugé à son horodatage. Un fix n'est pris que s'il est postérieur à l'ouverture de l'étape position (première ouverture ou « Replacer ») et précis ; le cache et son rejeu sont ignorés. Le témoin rouge reproduit la réserve R032 sur `34f3668` (S2 : le repère reste sur le cache) et passe au vert sur `709afe9`. Doublage R033 (N3, sous-agent frais) : GO, aucune réserve bloquante. Installé sur l'iPhone de Malik : `1.3.0 18` vérifié par `devicectl`. Le lancement a échoué, téléphone verrouillé.

- Tip de code : `709afe9dcad1dd59cce407f787b7ea348ac92fdc` (`ls-remote` confirmé). Rapport R033 committé : `be4c3971af4317c7246466194b86155ffd87a1d0` (`vault/revues/2026-10-21-R033-premier-fix-gps.md`).
- Mécanisme : `LocationRules.isFresh` et `LocationRules.firstFixEffect` (`Models/BookBox.swift`), `applyFirstFix` et `returnToMap` (`ViewModels/AddBoxViewModel.swift`). `autoCentered` supprimé. `Services/LocationService.swift` non modifié.
- Témoin : harnais hors dépôt (compile le vrai VM sur Mac Catalyst, stub de `SupabaseService`). Rouge sur `34f3668` : `FAIL S2 cache ancien puis fix live (pin=48.8566,2.3522)`, `ÉCHECS : 5`, exit 1. Vert sur `709afe9` : 11 contrôles PASS, `TOUT VERT`, exit 0.
- Build Release : `** BUILD SUCCEEDED **`. `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail. Budget `pre-commit --controle 709afe9…` : exit 0.
- Installation : build Debug signé, `devicectl device install app` rc 0, `device info apps` : `Boîtes à Livres  com.malikkaraoui.boitesalivresapp  1.3.0  18`. Identifiant `devicectl` de l'iPhone : `00008101-001278EA36E9001E` (le `C3CFC878-…` du mandat n'existe pas dans `devicectl`). Lancement refusé : téléphone verrouillé. À relancer à la main, déverrouillé.
- Worktrees `F01-M0040` et `F01-M0040-rev` retirés. Branche distante `feat/carte-localisation` conservée.

### Gestes de test terrain (iPhone de Malik, build 1.3.0 (18), à faire à la main)
1. Ouvrir « Ajouter une boîte » sans toucher la carte : la carte se centre sur ma position (300 m), le repère reste sur la position précédente.
2. Toucher la carte : le repère va au point touché. Glisser la carte : le repère ne bouge pas.
3. Étape formulaire, « Replacer » : la carte se recentre sur ma position, le repère reste où je l'ai mis.
4. Note : un seul saut de ligne, 100 caractères, pas de vue « France entière ». Précision et présence sur place : bouton grisé au-delà de 50 m.

### Remarques (issues à ouvrir, hors M0040)
- Fix reçu pendant le formulaire : après « Replacer », le repère ne suit pas la caméra jusqu'au fix suivant (R033, remarque 1).
- Présence sur place lit `LocationService.currentLocation` sans contrôle de fraîcheur : le cache peut valider la présence (préexistant, R033, remarque 2).
- Témoin : contrôle S7 sans assertion ; cas `timestamp == openedAt` non testé (R033, remarque 3).

Scellé tests : sans objet (`scripts/verifier-rendu.mjs` absent du dépôt).
Contre-témoins : sans objet (témoin hors dépôt).

M0040
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌ (volontaire : pas de merge sans GO du fondateur)
Main push           ❌ (volontaire)
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
