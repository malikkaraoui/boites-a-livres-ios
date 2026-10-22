---
date: 2026-10-21
tags: [ajout-boite, carte, epingle-centrale, build-19]
session: F01
mandat: ajout-boite-epingle-centrale
mandat_id: M0041
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0041
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-21T20:47:30+0200
---

# F01 / M0041 — « Ajouter une boîte » : retour à l'épingle fixe au centre (on bouge la carte), « Replacer » s'ouvre sur le point posé ; rapport R033 rangé ; build 19

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3**.

## Décision du fondateur (21/10/2026 20:46, build 18 testé), verbatim
« lorsque je clic sur replacer je dois juste bouger la carte et le pico de la boite reste au centre / plus simple ».
Elle remplace le choix « toucher la carte pour placer le repère » de M0039 (choix de l'orchestrateur, désavoué). Reste valable sa demande de 19:28 : carte zoomée, jamais la France entière, le point là où il l'a mis.

## Comportement voulu
- **Épingle fixe au centre** de la carte (comme avant M0039) : on fait glisser la carte, `pinCoordinate` = centre de la caméra. Plus de `MapReader`/toucher pour placer, plus d'`Annotation` déplaçable. Le point bleu de l'utilisateur (`UserAnnotation`) reste affiché.
- **Première ouverture** : mécanisme `LocationRules.isFresh` / premier fix frais de M0040 conservé : caméra (≈ 300 m) — donc l'épingle — centrée sur la première position fraîche, tant que l'utilisateur n'a pas encore bougé la carte. En attendant, cache s'il existe ; jamais la France entière si une position est connue.
- **« Replacer »** (retour de l'étape 2 à l'étape 1) : caméra zoomée (≈ 300 m) **centrée sur le point déjà posé** (`pinCoordinate`), donc l'épingle est là où il l'avait mise ; aucun recentrage automatique sur le GPS à ce retour (pas d'attente de fix). Le bouton « Centrer sur ma position » (s'il existe) recentre sur le GPS.
- Bandeau : « Déplace la carte pour placer la boîte ».
- Inchangé : note au-dessus du clavier, hauteur fixe + défilement, un saut de ligne, précision 50 m, présence 50 m, aucun changement de payload.
- Simplifie `firstFixEffect` en conséquence (plus de cas `cameraOnly` si inutile) ; supprime le code mort du toucher.

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucun changement de payload/endpoint/champ.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `be4c3971af4317c7246466194b86155ffd87a1d0`.
2. `.claude/worktrees/F01-M0041` absent ; aucun autre worktree sur `feat/carte-localisation`.

## Mise en place
`git worktree add .claude/worktrees/F01-M0041 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `be4c397…` collé (sinon STOP).

## Travail
1. **Rangement R033** : `be4c397` a ajouté le rapport au mauvais endroit (`BoitesALivresNative/vault/revues/2026-10-21-R033-premier-fix-gps.md`). `git mv` vers `vault/revues/2026-10-21-R033-premier-fix-gps.md` (contenu inchangé), commit `docs(revues): R033 rangé dans vault/revues`. Vérifie qu'aucun autre fichier n'existe sous `BoitesALivresNative/vault/` (`git ls-tree -r --name-only HEAD BoitesALivresNative/vault`) ; s'il y en a, range-les de même et dis-le.
2. **Épingle centrale** selon « Comportement voulu » (`App/AddBoxView.swift`, `ViewModels/AddBoxViewModel.swift`, `Models/BookBox.swift`).
3. **Version 19** : `project.yml` `CURRENT_PROJECT_VERSION: 19`, `project.pbxproj` aligné comme pour les builds 17/18, `CHANGELOG.md` « Build 19 » ; `release-notes/fr-FR.txt` et `en-US.txt` : seulement « build 18 » → « build 19 » (`grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).
4. **Tests** : logique pure hors dépôt (`swiftc`, vrai `Models/BookBox.swift` ; harnais de M0040 si réutilisable) : premier fix frais centre la carte quand l'utilisateur n'a pas bougé ; cache ancien ignoré ; carte bougée par l'utilisateur → plus de recentrage ; « Replacer » → caméra = point posé, pas de recentrage GPS ; cas note/précision de M0038. Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert.
5. Commits ciblés, push + `git ls-remote` collé. Tip de code = `T`.
6. **Doublage N3 `R034`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur le diff `709afe9dcad1dd59cce407f787b7ea348ac92fdc..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie fichier:ligne chaque point de « Comportement voulu », le rangement R033, build 19 cohérent, aucun changement de payload, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base 709afe9dcad1dd59cce407f787b7ea348ac92fdc` collé. Rapport **`vault/revues/2026-10-21-R034-epingle-centrale.md` (à la racine du dépôt, PAS sous `BoitesALivresNative/`)**, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé sur la branche + push + `ls-remote` collé.
7. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E …` (identifiant confirmé par M0040) ; lancement (téléphone verrouillé = le dire, pas un STOP) ; `device info apps` → `1.3.0 19` collé. `unavailable` → le dire.
8. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0041` dans ce fichier (5 lignes max en français simple ; preuves ; 3 gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0041` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0041

- **GO** (R034, tip `d426653`). Épingle fixe au centre, « Replacer » sur le point posé, build 19 ; R033 rangé dans `vault/revues/`.
- Tests : 22/22 sur le vrai `Models/BookBox.swift` (harnais hors dépôt) ; `asc.test.mjs` 17/17 ; `xcodebuild` Release generic iOS : BUILD SUCCEEDED.
- Installé sur l'iPhone de Malik : `device info apps` = `1.3.0 19`. Lancement refusé, téléphone verrouillé (à relancer à la main).
- Remarques ouvertes en issues : #39 (pincement), #40 (géocodage pendant le glisser), #41 (position absente sans fix frais).
- Branche `feat/carte-localisation` poussée : `1436bae` (rapport R034 par-dessus le tip de code `d426653`). Merge sur `main` : non fait (interdit par le mandat).

**Tests terrain (à faire sur l'iPhone) :**
1. Ouvrir « Ajouter une boîte », glisser la carte : l'épingle reste au centre, la carte seule bouge.
2. Toucher « Replacer » : la carte revient sur le point posé, sans sauter sur le GPS.
3. Première ouverture sans toucher la carte : la carte se centre sur ta position (≈300 m) ; l'épingle tombe bien au centre (à valider à l'écran).

M0041
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌
Main push           ❌
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
