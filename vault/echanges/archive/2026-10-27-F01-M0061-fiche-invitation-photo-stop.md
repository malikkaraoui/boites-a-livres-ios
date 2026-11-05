---
date: 2026-10-27
tags: [fiche, photo, invitation, build-31, merge]
session: F01
mandat: fiche-invitation-photo
mandat_id: M0061
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0061
branche: feat/fiche-invitation-photo
niveau: N3
derniere_maj: 2026-10-27T12:05:11+0100
---

# F01 / M0061 — Fiche d'une boîte sans photo : invitation à prendre la première photo (texte selon la distance, 300 m) ; build 31 ; fusion ; installation iPhone

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre. **Va jusqu'au bout** : un rendu partiel n'est valable que pour un STOP nommé (cause + preuve).

Modèle : Haiku 5.5 medium (doublage compris). **N3** à cause de la version (`project.yml`/`project.pbxproj`). Android fait la même chose en parallèle dans son propre dépôt : tu n'y touches pas.

## Demande du fondateur (verbatim, datée — ne pas re-débattre)
- 27/10 11:21, capture de la fiche #10504 (cadre gris avec icône photo vide) : « À la place de la photo vide, met plutôt un truc qui demande s'il est sur les lieux de prendre une photo... si il voit cela depuis son canapé et que la photo est à moins de 300m alors le message change et devient .., un truc du genre, votre première photo est à moins de 300m la communauté vous remercie déjà ».
- Proposition de l'orchestrateur 27/10 11:23, **validée « Parfait — Android et iOS » le 27/10 12:02** :
  - utilisateur à **plus de 300 m** de la boîte (ou position inconnue) : « Pas encore de photo. Tu passes devant ? Prends la première ! »
  - utilisateur à **300 m ou moins** : « Tu es à moins de 300 m : ta photo sera la première de cette boîte, la communauté te remercie déjà ! »
  - toucher le cadre = ouvrir l'ajout de photo existant.

## Règles
1. Seul le cas « boîte sans aucune photo publiée » change (cadre vide de `Views/Components/PhotoCarousel.swift` et/ou `Views/Detail/DetailView.swift`, à établir fichier:ligne). Le cadre d'une photo en échec de chargement (placeholder #22) reste tel quel. L'envoi en cours (isUploading) reste tel quel.
2. Dans le cadre : une icône appareil photo + le texte selon la distance (règle ci-dessus). Distance = la même que la fiche utilise déjà (`DetailView.swift` `distanceFromUser(to:)`, `LocationService.shared.currentLocation` en LECTURE seule). Seuil : nouvelle constante `photoInviteMeters = 300` dans `enum LocationRules` (`Models/BookBox.swift:180`). Le texte suit la position si l'écran observe déjà la position ; sinon un calcul à l'affichage suffit — dire lequel au rapport.
3. Toucher le cadre = **exactement le même geste que le bouton « Ajouter une photo » existant de la fiche**, avec sa règle des 100 m INCHANGÉE (si ce bouton est inactif, le toucher du cadre ne fait rien de plus). Aucun nouveau circuit d'envoi.
4. Textes dans `Localizable.xcstrings`, FR + EN : EN = « No photo yet. Passing by? Take the first one! » et « You're less than 300 m away: your photo will be the first of this box, the community already thanks you! ». Lisible en mode sombre (capture du fondateur en sombre).
5. **Ne touche pas** : `ViewModels/DetailViewModel.swift`, `Services/LocationService.swift`, `Services/PhotoService.swift`, `App/Constants.swift` (zones critiques). S'il faut les modifier : STOP propre avec la raison. Aucun changement de payload, d'endpoint, de base.

## Version 31
`project.yml` `CURRENT_PROJECT_VERSION: 31` (MARKETING 1.3.0 inchangé), `project.pbxproj` aligné, `CHANGELOG.md` « Build 31 : fiche sans photo, invitation à prendre la première photo (texte différent à moins de 300 m) » ; `release-notes/fr-FR.txt` et `en-US.txt` : « build 30 » → « build 31 » seulement.

## Interdits permanents
Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase, de `stash`, de `reset --hard`, de `checkout -- .`. `git add` ciblé. **Aucune écriture Supabase. Aucun appel à Apple** (ni release, ni archive App Store, ni TestFlight : il faut « OK Apple » du fondateur). Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`. Rapports de revue sous `vault/revues/` à la racine. Refus d'un hook : STOP.

## Garde (écart = STOP)
`git fetch origin --prune` ; `git rev-parse origin/main` = `6b86312d2de93fe8250e9f37e3e0395bfb2898c6`.

## Mission 0 — scope git strict
Scratch détaché sur `origin/main` : commit ciblé de `vault/echanges/archive/2026-10-23-F01-M0058-publication-app-store-1.3.0-build-28.md` s'il n'est pas suivi (`docs(vault): reconciliation orchestrateur -- archive M0058`), push `HEAD:main`, `ls-remote` collé. Rien d'autre.

## Travail
1. `git worktree add -b feat/fiche-invitation-photo .claude/worktrees/F01-M0061 origin/main`. Issue `gh issue create` « Fiche sans photo : inviter à prendre la première photo » ; numéro cité dans les commits.
2. Règles 1-5 ; version 31.
3. **Tests** : Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert ; test unitaire du choix du texte (> 300 m, = 300 m, < 300 m, position inconnue) si une fonction pure s'y prête.
4. **Preuve d'écran** (gabarit §10) : simulateur, fiche d'une boîte sans photo, position simulée (`xcrun simctl location <udid> set <lat>,<lng>`) à ~1 km puis à ~150 m de la boîte ; captures AVANT (cadre vide actuel) et APRÈS (deux textes), mode sombre, dans `vault/revues/captures-M0061/`, noms parlants, citées au rapport. Impossible → axe UX ⚠️ « non vérifié à l'écran » + checklist fondateur.
5. Commits ciblés, push + `ls-remote` collé. Tip de code = `T`.
6. **Doublage N3 `R051`** (relu dans `state.json`) sur `origin/main..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule ; vérifie règles 1-5 fichier:ligne, seuil 300 m (bornes), geste du cadre = bouton existant, zones critiques intactes, version 31 cohérente, refait les captures ou contrôle les tiennes, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base $(git merge-base origin/main T)` collé. Rapport `vault/revues/2026-10-27-R051-fiche-invitation-photo.md`, frontmatter fermé : `verdict: GO|RESERVE`, `tip:` (sha 40), `niveau: N3`. RESERVE → correctif → re-relecture (`R051b`…) ; loi des deux patchs.
7. **Si GO : fusion sur `main`** (gabarit §9 mode direct, `.claude/skills/orchestration-bureau/references/gabarits.md` lu en entier), push, `ls-remote` collé ; branche et worktrees retirés.
8. **Installation sur l'iPhone de Malik** (Wi-Fi), comme M0059 étape 7 (`vault/echanges/archive/F02-M0059.md`) → `device info apps` collé → `1.3.0 31`. Injoignable → le dire, pas un STOP.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0061` dans ce fichier (5 lignes max en français simple ; ce qui n'a PAS été vu à l'écran ; checklist fondateur de 3 à 5 gestes sur iPhone : quelle fiche ouvrir, où se placer, ce qu'il doit voir ; preuves) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; ne modifier que `windows.F01`, `last_event`, `updated_at`, et avancer `next_revue_id`) → commit vault ciblé sur `main` + push + `ls-remote` collé → footer de statut (gabarit §4, première ligne `M0061`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0061 — STOP propre : non fusionné, non installé

- **Fait** : branche `feat/fiche-invitation-photo` poussée, tip `67967bc` ; issue #69 ; build 31 sur la branche. `main` non modifié par ce mandat (seule l'archive M0058 a été reportée : `5c87ef8`).
- **Preuves** : build Release `BUILD SUCCEEDED` (exit 0) après chaque commit ; `node --test scripts/release/asc.test.mjs` 17/17 ; seuils 300 m (300.0 proche, 300.01 loin, nil loin) 6/6 par script Swift isolé, le projet n'ayant pas de cible de tests unitaires.
- **Cause du STOP** : deux correctifs successifs sur le même mécanisme (conditions d'affichage de l'invitation dans `DetailView.swift`), après RESERVE R051 (chargement, `9dddc79`) et R051b (garde de rendu l.31 : la section photo n'était jamais rendue pour une boîte sans photo, `67967bc`). Règle « deux correctifs de suite sur la même classe : on s'arrête et on le dit ».
- **Non relu** : `67967bc` n'a pas de verdict GO. R051b portait sur `9dddc79`. Pas de fusion, pas d'installation.
- **Pas vu à l'écran** : tout. Aucune capture AVANT/APRÈS, aucun simulateur. Le défaut R051b n'aurait été attrapé que par un rendu réel.
- **Arbitrage pour le fondateur** : (a) vérification à l'écran puis relecture fraîche de `67967bc`, merge si GO ; recommandation : (a), car le défaut ne se voit qu'à l'écran.
- **Checklist fondateur (après merge, sinon à tester sur la branche)** :
  1. Fiche d'une boîte sans aucune photo publiée, à plus de 300 m : le cadre gris montre l'appareil et « Pas encore de photo. Tu passes devant ? Prends la première ! ».
  2. Se placer à moins de 300 m (simulateur : `xcrun simctl location <udid> set <lat>,<lng>`) : le texte devient « Tu es à moins de 300 m : ta photo sera la première de cette boîte, la communauté te remercie déjà ! ».
  3. Toucher le cadre à moins de 100 m : la feuille « Ajouter une photo » s'ouvre ; au-delà de 100 m, rien (comme le bouton).
  4. Fiche avec photos : rien ne change ; pendant le chargement, aucun texte d'invitation.
  5. Mode sombre : texte lisible.
- **Interprétation prise** : la section photo apparaît aussi pour une fiche chargée sans photo (sinon l'invitation est inatteignable) ; la mise en page de ces fiches gagne donc un cadre de 220 pt.
- **Décision de statut** : `statut: reponse-disponible` posé en dernier geste ; état runtime limité aux champs listés (`last_event`, `updated_at`, `next_revue_id`).

M0061
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ❌
Merge main          ❌
Main push           ❌
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
