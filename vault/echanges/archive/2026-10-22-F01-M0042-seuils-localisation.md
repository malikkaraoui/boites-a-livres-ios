---
date: 2026-10-22
tags: [localisation, seuils, confirmation, deplacement, build-20]
session: F01
mandat: localisation-seuils-confirmation-deplacement
mandat_id: M0042
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0042
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-22T20:27:11+0200
---

# F01 / M0042 — Écran « Localisation » : confirmation jusqu'à 50 m de précision, déplacement minimal max(20 m, 2 × précision) ; build 20

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3**.

## Retour terrain et décisions du fondateur (22/10/2026), verbatim
12:22 : « le bouton est grisé parce que ma position GPS et la position du point d'intérêt boîte à livres ne sont pas scrupuleusement l'un sur l'autre alors que j'aurais aimé [dire] oui elle se trouve ici. Sinon on va faire face à une remontée d'information qui consiste à dire que la boîte à livres s'est déplacée de 2 m ou de 3 m ou de 5 m ou de 10 m. Ce qui est normal parce qu'on est dans la zone d'incertitude du GPS. […] si je déplace la boîte à livres, je peux tout d'un coup valider le fait qu'elle s'est déplacée même 21 m [à ±15 m], ce qui est pas logique du tout ».
20:26 : « Confirmation : si tu ne bouges pas la carte et que tu es à 50 m ou moins de la boîte, avec une précision de 50 m ou mieux, tu peux confirmer. = OUI » ; « Déplacement : il ne compte que s'il dépasse le plus grand de ces deux seuils, 20 m ou deux fois ta précision. À ±15 m, il faut donc déplacer de plus de 30 m. En dessous, le bouton devient « Oui, elle est bien ici » et rien ne bouge en base. Le maximum de 100 m reste en place. = OUI » ; « lance les travaux ».

## Règles à implémenter (`Views/Components/LocationUpdateSheet.swift`, `Models/BookBox.swift` `LocationRules`)
État actuel (tip `1436bae`) : `pinMoved` = repère à ≥ 1 m de la boîte (l.39) → `.move` ; `.confirm` exige `canSend` (≤ 10 m, l.43) ; `.move` exige `canSendManual` (≤ 50 m) et `pinDistance ≤ moveMaxMeters` (100 m) ; présence `nearEnough` ≤ `presenceMeters` (50 m).
1. **Seuil de déplacement** : fonction pure `LocationRules.moveMinMeters(accuracy:) = max(20, 2 × accuracy)`. `kind` = `.move` **seulement si** `pinDistance > moveMinMeters(accuracy)` ; sinon `.confirm` (même si le repère a un peu bougé).
2. **Confirmation** : permise si téléphone à ≤ 50 m de la boîte (`presenceMeters`) ET précision ≤ 50 m (`canSendManual`). Plus d'exigence ≤ 10 m. Envoi `.confirm` comme aujourd'hui (coordonnées GPS du téléphone), **avec `source` = `LocationRules.source(accuracy:, pinIsGPS: true)`** : `gps` si précision ≤ 10 m, sinon `manual`. Raison : contrainte de production `location_updates_accuracy_ck` (dépôt admin, `supabase/migrations/20261019180000_location_updates_precision_manuelle.sql`) : `accuracy_m` ≤ 10, ou `source = 'manual'` et ≤ 50. **Aucune migration, aucun changement de champ ni d'endpoint.**
3. **Déplacement** : permis si `moveMinMeters < pinDistance ≤ 100 m`, présence ≤ 50 m, précision ≤ 50 m (inchangé). Au-delà de 100 m : grisé + « Tu ne peux pas déplacer la boîte de plus de 100 m. » (inchangé).
4. **Libellé du bouton** : `.confirm` → « Oui, elle est bien ici » ; `.move` → « Envoyer le nouvel emplacement ». Quand le repère a bougé mais reste sous le seuil, une ligne grise : « Écart de X m : dans la marge du GPS (moins de Y m), la boîte reste à sa place. » (X = `pinDistance` arrondi, Y = seuil arrondi).
5. **Textes** : retire le message orange « Précision entre 10 et 50 m : déplace la carte pour placer le repère sur la boîte, puis envoie. » et tout texte qui contredit ces règles. Le texte d'attente du GPS ne parle plus de 10 m.
6. **Version 20** : `project.yml` `CURRENT_PROJECT_VERSION: 20`, `project.pbxproj` aligné comme pour les builds précédents, `CHANGELOG.md` « Build 20 » ; `release-notes/fr-FR.txt` et `en-US.txt` : seulement « build 19 » → « build 20 » (`grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucune migration, aucun changement de payload/endpoint/champ.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`. Rapports de revue **sous `vault/revues/` à la racine du dépôt**, jamais sous `BoitesALivresNative/`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `1436bae51e66c20da3d45779fef409203bc79fdc`.
2. `.claude/worktrees/F01-M0042` absent ; aucun autre worktree sur `feat/carte-localisation`.

## Mise en place
`git worktree add .claude/worktrees/F01-M0042 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `1436bae…` collé (sinon STOP).

## Travail
1. Issue GitHub `gh issue create` « Localisation : confirmation jusqu'à 50 m, déplacement minimal max(20 m, 2 × précision) » avec les décisions verbatim ; numéro cité dans les commits. Ne la ferme pas.
2. Implémente les règles 1 à 6.
3. **Tests** : logique pure hors dépôt (`swiftc`, vrai `Models/BookBox.swift`, la décision extraite en fonction pure, ex. `LocationRules.locationAction(pinDistance:accuracy:userDistance:) -> confirm | move | blocked(raison)`) : ±5 m écart 15 m → confirm ; ±5 m écart 21 m → move ; ±15 m écart 21 m → confirm (cas du fondateur) ; ±15 m écart 31 m → move ; ±12 m repère non bougé → confirm permis (cas du fondateur, photo 1) ; ±51 m → bloqué ; téléphone à 51 m → bloqué ; écart 101 m → bloqué ; `source` ±8 → gps, ±12 → manual, ±50 → manual. Rouge sur `1436bae` pour les deux cas du fondateur, vert sur le nouveau tip (coller les deux). Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert.
4. Commits ciblés, push + `git ls-remote` collé. Tip de code = `T`.
5. **Doublage N3 `R035`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur `1436bae51e66c20da3d45779fef409203bc79fdc..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie fichier:ligne chaque règle, la conformité à la contrainte de production (aucun envoi possible avec `source=gps` et précision > 10 m), aucun changement de payload, build 20 cohérent, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base 1436bae51e66c20da3d45779fef409203bc79fdc` collé. Rapport `vault/revues/2026-10-22-R035-seuils-localisation.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé + push + `ls-remote` collé.
6. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E …` ; lancement (verrouillé = le dire) ; `device info apps` → `1.3.0 20` collé. `unavailable` → le dire.
7. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0042` dans ce fichier (5 lignes max en français simple ; preuves dont rouge/vert ; 4 gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0042` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0042

- Code poussé : `2e87c53` (règles 1 à 6, build 20), issue #42 ; relecture R035 **GO**, 0 réserve prouvée, rapport `b397856` poussé (`git ls-remote` = `b397856…`).
- Preuves : confirmation ±15 m / écart 21 m → `confirm` (vert) ; même cas sur `1436bae` → `canSend` refuse, écart 21 m part en `move` (**rouge**) ; 16 cas purs verts ; Release `BUILD SUCCEEDED` (0 erreur) ; `node --test scripts/release/asc.test.mjs` 17/17.
- **Installation NON faite** : « iPhone de Malik » verrouillé (`CoreDeviceError 10003`). Build Debug signé (generic iOS) OK, install refusée. Pas de `device info apps`. À faire après déverrouillage.
- Choix pris : commits avec `Co-Authored-By: Claude Haiku 5.5` et `Malik & Claude` ; texte « Précision insuffisante » inchangé ; `ProximityAlertService` : « 10 m » → « 50 m au plus » (contredit la règle 5) ; `source` de la confirmation = `LocationRules.source(…, pinIsGPS: true)`.
- Remarques R035 en issues #43 à #48 (arrondi du seuil, commentaire périmé, libellé « envoie », fraîcheur GPS, bouton grisé après échec pré-existant, contrainte `manual ≤ 50` à vérifier en prod).

Gestes de test terrain (après déverrouillage de l'iPhone et installation) :
1. Boîte à ±15 m de précision, téléphone à moins de 50 m, carte non déplacée : « Oui, elle est bien ici » actif.
2. Repère déplacé de 21 m à ±15 m : toujours « Oui, elle est bien ici », ligne grise « Écart de 21 m… ».
3. Repère déplacé de 31 m à ±15 m : « Envoyer le nouvel emplacement ».
4. Repère à plus de 100 m : bouton grisé, « Tu ne peux pas déplacer la boîte de plus de 100 m. ».

Gabarit §4 :

```
M0042
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌
Main push           ❌
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
```

Scellé tests / Contre-témoins : sans objet (aucun test neuf commité ; tests Swift hors dépôt).
