---
date: 2026-10-22
tags: [formulaires, champ-manquant, avis, build-22]
session: F01
mandat: rappel-champ-manquant-bouton-grise
mandat_id: M0045
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0045
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-22T21:06:54+0200
---

# F01 / M0045 — Bouton d'envoi grisé touché : faire clignoter ce qui manque (tous les formulaires) ; build 22

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3** (`project.yml`/`project.pbxproj`, `ViewModels/AddBoxViewModel.swift`).

## Retour terrain du fondateur (22/10/2026 21:05, build 20, écran « Donner mon avis »), verbatim
« Je pensais avoir tout rempli. Mais au final j'ai pas sélectionné l'état de la boîte à livres tout en haut. Il faut le rappeler si c'est le cas. [Si] Envoyer mon avis est grisé et que l'utilisateur appuie dessus alors faire clignoter les états à sélectionner possibles ou l'input à renseigner. Une fois que je sélectionne l'état c'était bon, j'ai pu envoyer mon avis. »

## Règle unique, pour TOUS les formulaires d'envoi
Au moins : `Views/Components/ReviewSubmitSheet.swift` (avis), `Views/Components/DeletionRequestSheet.swift` (suppression), `App/AddBoxView.swift` (ajout de boîte, étape 2), `Views/Components/LocationUpdateSheet.swift` (localisation), et tout autre écran dont le bouton d'envoi se grise (recense-les par grep `.disabled(` sur un bouton d'envoi ; liste au rapport).
1. Le bouton d'envoi **garde son aspect grisé** quand il manque quelque chose, mais **reçoit le toucher** (aujourd'hui `.disabled(!canSubmit)`, ex. `ReviewSubmitSheet.swift:412`, bloque le toucher). Toucher alors **n'envoie rien** ; il :
   - fait **défiler** jusqu'au premier élément manquant (dans l'ordre de l'écran, de haut en bas) ;
   - le fait **clignoter** (2 à 3 pulsations de la bordure/fond en couleur d'alerte, ≈ 1 s au total ; respecte « Réduire les animations » : simple surlignage fixe) ;
   - affiche sous l'élément un court message (ex. « Choisis l'état de la boîte ») ;
   - léger retour haptique d'erreur.
2. Les éléments manquants se lisent dans la **même logique** que `canSubmit` (une seule source de vérité : une fonction qui rend la liste ordonnée des manques, ex. `missingRequirements() -> [Requirement]` ; `canSubmit` = liste vide). Pas de règle en double.
3. Conditions qui ne dépendent pas d'un champ (ex. précision GPS insuffisante, trop loin de la boîte, déplacement > 100 m) : clignoter le message d'explication déjà affiché, sans autre changement.
4. Bouton actif : comportement d'envoi strictement inchangé. **Aucun changement de payload, d'endpoint ni de champ envoyé.**

## Version 22
`project.yml` `CURRENT_PROJECT_VERSION: 22`, `project.pbxproj` aligné, `CHANGELOG.md` « Build 22 » ; `release-notes/fr-FR.txt` et `en-US.txt` : seulement « build 21 » → « build 22 » (`grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucune migration, aucun changement de payload.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude` (pas d'autre trailer). Rapports de revue **sous `vault/revues/` à la racine du dépôt**.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `da9f8db4dd035961ecfb5065fb9572a4fdc1e1da`.
2. `.claude/worktrees/F01-M0045` absent ; aucun autre worktree sur `feat/carte-localisation`.

## Mise en place
`git worktree add .claude/worktrees/F01-M0045 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `da9f8db…` collé (sinon STOP).

## Travail
1. Issue `gh issue create` « Bouton d'envoi grisé : faire clignoter ce qui manque » avec le retour verbatim ; numéro cité dans les commits. Ne la ferme pas.
2. Applique la règle à chaque formulaire recensé ; version 22.
3. **Tests** : logique pure hors dépôt (`swiftc`) sur la/les fonctions `missingRequirements` : avis sans état → [état] ; avis complet → [] ; suppression sans motif (si requis) → [motif] ; ajout sans photo → [photo] ; ordre haut→bas respecté ; `canSubmit == missing.isEmpty` pour chaque cas. Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert. Captures simulateur si possible (`vault/revues/captures-M0045/`) ; sinon le dire, checklist fondateur.
4. Commits ciblés, push + `git ls-remote` collé. Tip de code = `T`.
5. **Doublage N3 `R037`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur `da9f8db4dd035961ecfb5065fb9572a4fdc1e1da..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie fichier:ligne chaque formulaire (toucher reçu quand grisé, rien n'est envoyé, défilement + clignotement + message, une seule source de vérité, « Réduire les animations »), recensement complet, aucun changement de payload, build 22 cohérent, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base da9f8db4dd035961ecfb5065fb9572a4fdc1e1da` collé. Rapport `vault/revues/2026-10-22-R037-champ-manquant.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé + push + `ls-remote` collé.
6. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E …` ; lancement (verrouillé = le dire) ; **`device info apps` collé tel quel** → `1.3.0 22`. `unavailable` ou verrouillé → le dire.
7. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0045` dans ce fichier (5 lignes max en français simple ; formulaires recensés ; preuves ; gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0045` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0045

Le bouton d'envoi grisé reçoit maintenant le toucher. Il fait défiler, clignoter et écrire le manque, sans rien envoyer. Cinq formulaires traités : avis, suppression, ajout de boîte (étape 2), localisation. Build 22 installé sur l'iPhone de Malik (`1.3.0 22`).

- Code : commit `fc50cb3`, poussé. Rapport de revue `20370d0`, poussé (`ls-remote` identique).
- Revue R037 : GO. Réserve « phase échec de la localisation » prouvée par lecture seulement : classée remarque, issue #52.
- Issue créée : #51 (retour du fondateur), non fermée. Remarques : #52.

Formulaires recensés (grep `.disabled(`) : `ReviewSubmitSheet` (avis), `DeletionRequestSheet` (suppression), `AddBoxView` (ajout, étape 2), `LocationUpdateSheet` (localisation). Les autres `.disabled(` sont des boutons d'ouverture, pas des envois.

Preuves :
- `xcodebuild` Release iOS : BUILD SUCCEEDED (un avertissement, hors fichiers touchés : `DetailView.swift:442`).
- Tests de logique pure (`swiftc`, hors dépôt) : 25 cas verts, dont ordre haut → bas.
- `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail.
- Budget : `controle-instructions` 4 OK, 0 BLOQUÉ.
- `xcodebuild` Debug iPhone de Malik : BUILD SUCCEEDED. Install et lancement OK. `device info apps` : `Boîtes à Livres  com.malikkaraoui.boitesalivresapp  1.3.0  22`.

Gestes de test terrain (non faits ici, à faire sur l'iPhone) :
1. Avis sans état, toucher « Envoyer mon avis » : défilement vers l'état, clignotement, message « Choisis l'état de la boîte », vibration. Choisir un état : l'envoi part.
2. Demande de suppression sans motif : clignotement du champ, rien n'est envoyé.
3. Ajout de boîte sans photo : clignotement de la photo, message. Loin de la boîte : clignotement de l'indication.
4. Localisation à plus de 50 m : clignotement du bandeau de distance.
5. Réglages › Accessibilité › « Réduire les animations » : surlignage fixe, pas de pulsation.

Simulateur : pas de capture faite (pas de simulateur iOS utilisé pour ce mandat).

Scellé et contre-témoins : sans objet (pas de correctif de suite).

Merge main : volontairement non fait. Main push : volontairement non fait.

M0045
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌
Main push           ❌
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
