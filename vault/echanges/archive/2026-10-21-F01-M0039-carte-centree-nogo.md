---
date: 2026-10-21
tags: [ajout-boite, carte, build-18]
session: F01
mandat: ajout-boite-carte-centree-doublage-installation
mandat_id: M0039
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0039
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-21T19:54:45+0200
---

# F01 / M0039 — « Ajouter une boîte » : carte centrée sur l'utilisateur, repère conservé (option A) ; doublage N3 de tout le build 18 ; installation

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3**.

## Contexte
M0038 (archive `vault/echanges/archive/2026-10-21-F01-M0038-ajout-boite-stop-carte.md`, lis-la) a livré sur `feat/carte-localisation` (`fe48b53`) : note au-dessus du clavier, un saut de ligne, précision 50 m, build 18, issue #38. Il s'est arrêté au point 4 : le repère est une épingle fixe au centre de la carte (`App/AddBoxView.swift` l.51-59 : `onMapCameraChange` → `vm.pinCoordinate = ctx.region.center`), donc centrer sur le GPS effaçait le point posé.

## Décision du fondateur (verbatim, 21/10 19:28, feu vert 19:44)
« J'aimerai une carte center sur moi et le point d'intérêt là où je l'ai déjà mis. » = **option A** du rapport M0038. Précision d'interaction choisie par l'orchestrateur : le repère devient un marqueur dessiné à sa coordonnée ; **un toucher sur la carte place le repère à l'endroit touché** (et, si simple, le marqueur se fait aussi glisser au doigt). Glisser/zoomer la carte ne déplace plus le repère.

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucun changement de payload/endpoint/champ.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `fe48b535e64add30c1c4f3c24843142ead43a43a`.
2. `.claude/worktrees/F01-M0039` absent ; aucun autre worktree sur `feat/carte-localisation` (`git worktree list`).

## Mise en place
`git worktree add .claude/worktrees/F01-M0039 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `fe48b53…` collé (sinon STOP).

## Travail
1. **Carte étape 1/2 (`App/AddBoxView.swift`, `ViewModels/AddBoxViewModel.swift`)** :
   - Repère = `Annotation`/marqueur à `vm.pinCoordinate` (même icône `mappin.circle.fill`), plus l'épingle fixe au centre ; supprime l'écriture de `pinCoordinate` dans `onMapCameraChange`.
   - Toucher la carte → `pinCoordinate` = point touché (`MapReader` + `proxy.convert`). Glisser le marqueur si simple ; sinon le toucher suffit (le dire au rapport).
   - Point bleu de l'utilisateur affiché (`UserAnnotation`).
   - **Ouverture et chaque retour à l'étape position (« Replacer »)** : caméra centrée sur le GPS actuel, distance ≈ 300 m ; repère inchangé. Premier passage sans GPS : dès le premier fix, caméra ET repère sur le GPS, **tant que l'utilisateur n'a pas touché la carte**. Jamais de vue « France entière » quand une position est connue.
   - Texte du bandeau : « Touche la carte pour placer la boîte ». Le bouton « Replacer » de l'étape 2 et « Centrer sur ma position » (s'il existe) gardent leur rôle ; « Centrer sur ma position » recentre la caméra ET place le repère sur le GPS.
   - Les règles de présence et de précision de M0038 sont inchangées (repère à ≤ 50 m du GPS, précision ≤ 50 m).
2. **Tests** : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; logique pure de M0038 rejouée (`swiftc`, cas note + précision) ; `node --test scripts/release/asc.test.mjs` vert. Captures simulateur si possible (étape 1 avec GPS simulé : carte centrée, repère visible ; après « Replacer ») dans `vault/revues/captures-M0039/` ; impossible → le dire, checklist fondateur.
3. Commit ciblé `feat(ajout-boite): carte centrée sur l'utilisateur, repère conservé (#38)`, push + `git ls-remote` collé. Tip = `T`.
4. **Doublage N3 `R032`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur **tout** le diff `fa159395238d5ee2f09151912a7b5a40e7ce8d77..T` (M0038 + M0039) : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie fichier:ligne : note au-dessus du clavier, hauteur fixe + défilement interne, un seul saut de ligne (saisie, collage, envoi), précision 50 m, carte centrée sur GPS avec repère conservé, toucher = placer, pas de vue France quand GPS connu, aucun changement de payload, build 18 cohérent (`project.yml`, `pbxproj`, CHANGELOG, notes « build 18 » sans autre changement), budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base fa159395238d5ee2f09151912a7b5a40e7ce8d77` collé. Rapport `vault/revues/2026-10-21-R032-ajout-boite.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé sur la branche + push + `ls-remote` collé.
5. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A …` ; lancement ; `device info apps` → `1.3.0 18` collé. `unavailable` → le dire (pas un STOP).
6. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0039` dans ce fichier (5 lignes max en français simple ; preuves ; 4 gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0039` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0039

- **Résultat : NO-GO (R032), arrêt propre.** Le repère est désormais un marqueur posé au toucher ; la carte se centre sur le GPS (300 m) à l'ouverture et à « Replacer ».
- **Bloquant, non corrigé :** le premier fix GPS live n'est pas appliqué quand un cache existe. Le cache `CLLocationManager` consomme le premier fix (`@Published` rejoue sa valeur à l'abonnement de `onReceive`, `App/AddBoxView.swift`).
- **Deux correctifs de suite sur la même classe** (`3759e82` puis `34f3668`) : le mécanisme est en cause ; on s'arrête (règle CLAUDE.md, 2e réserve de même classe = STOP). Le correctif suivant est un arbitrage (`dropFirst()` ou critère `timestamp >= ouverture`).
- **Installation sur l'iPhone : non faite** (pas de GO). Build Release OK, node 17/17, logique note et précision OK.
- **Branche :** `feat/carte-localisation` poussée à `3b6e5b3` (code `34f3668` + rapport R032 `vault/revues/2026-10-21-R032-ajout-boite.md`). Non fusionnée, non mergée sur `main`.

**Gestes de test terrain** (à faire après le correctif, sur un appareil) :
1. Ouvrir « Ajouter une boîte » sans cache GPS : la carte doit se centrer sur toi (≈300 m) au premier fix, repère compris.
2. Ouvrir avec un cache GPS ancien (ville différente) : la carte doit aller sur ta position réelle dès le premier fix live.
3. Toucher la carte : le repère va au point touché ; glisser la carte ne le déplace pas.
4. « Replacer » depuis l'étape formulaire : caméra recentrée sur le GPS, repère inchangé.

Mécanisme et preuves : `vault/revues/2026-10-21-R032-ajout-boite.md` (tours 1 et 2, sous-agents frais, lecture seule).

M0039
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ❌
Merge main          ❌
Main push           ❌
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
