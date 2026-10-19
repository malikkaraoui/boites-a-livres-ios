---
date: 2026-10-18
tags: [reglages, moderation, affichage]
session: F01
mandat: motif-refus-et-date-reglages
mandat_id: M0013
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0013
branche: fix/reglages-motif-date
niveau: N1
derniere_maj: 2026-10-18T17:10:03+0200
---

# F01 / M0013 — Réglages : afficher le motif de refus et une vraie date

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question que tu aurais posée, les options que tu voyais et celle que tu aurais choisie avec sa raison, puis applique les rituels de fin. Un STOP propre est un rendu valable et laisse l'orchestrateur décider ; une question laisse un mandat mort. Vaut aussi pour une demande d'autorisation d'outil : n'insiste pas ; contourne par une commande plus simple (lecture seule, `git show`, `git -C`, chemin explicite) ; sinon STOP propre.

## Interdits permanents
- Jamais de `sleep`, jamais de tâche de fond vivante à la sortie ; `rm -rf` seulement sous forme gardée `"${VAR:?}/${SOUS:?}"`.
- Git : `git add` ciblé, jamais `-a`/`-A` ; jamais `stash`/`reset --hard`/`checkout -- .` à la racine ; jamais de rebase ; jamais `--no-verify`.
- **AUCUNE écriture en production Supabase** (base ou stockage) dans ce mandat : lecture seule, et tests sur données simulées.
- Ne jamais afficher ni écrire une clé (service ou anon) dans un fichier suivi, un log ou le rapport.
- Signature des commits : message en heredoc terminé par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3, verbatim)
(1) lecture/recherche parallèle = agents FRAIS (jamais `fork`) ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, ni ne tue un autre agent ; (3) tout rapport de sous-agent est VÉRIFIÉ (fichier:ligne recontrôlés) avant le livrable ; (4) après tout incident : git status/diff/log/reflog AVANT toute autre action ; (5) ATTENDRE LE RETOUR DE TOUS les sous-agents avant le premier rituel de fin — jamais `sleep` ni sondage ; échec de l'un = STOP propre.

## Constat terrain (fondateur, 18/10 17:07, capture iPhone)
Réglages › Mes soumissions : « Photo · Boîte #14183 — Refusée » s'affiche, mais **sans le commentaire de modération** (« Merci ! »), alors que la notification le montrait ; et la date s'affiche brute : `2026-10-17T14:03:35.035649+0:00`.

## Cause (vérifiée dans le code par l'orchestrateur, à recontrôler)
- `App/SettingsView.swift` (section « Mes soumissions ») : `PhotoSubmission.review_notes` (décodé, `Services/SupabaseService.swift:330`, renvoyé par la RPC `my_photo_submissions`) **n'est affiché nulle part**. Même vérification pour les soumissions de boîtes et les demandes de suppression si elles ont un motif de modération.
- `relativeDate(from:)` (`App/SettingsView.swift:517`) utilise `ISO8601DateFormatter()` sans `.withFractionalSeconds` : `2026-10-17T14:03:35.035649+00:00` n'est pas lu → la chaîne brute s'affiche. Gérer avec ET sans fractions (et microsecondes : 6 chiffres).
- Ne touche PAS `SettingsViewModel.swift` ni `SupabaseService.swift` (zone critique) : si c'est indispensable, STOP (passer en N3).
- Tests : pas de cible de tests dans le projet ; fonction de date extraite en fonction pure + harnais `swiftc` hors dépôt (cas : avec 6 décimales, avec 3, sans, invalide) ; build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`.
- Version : reste **1.3.0 build 9** (non envoyée) ; ajouter une entrée « Corrigé » au `CHANGELOG.md` section 1.3.0 + notes App Store FR.

## Attendu
- Sous une soumission refusée (et acceptée si un message existe), le motif s'affiche en petit texte secondaire, préfixé « Motif : » (FR) / « Reason: » (EN, localisé comme le reste). Rien si vide.
- La date s'affiche en relatif court (« il y a 1 j »), jamais brute.

## Garde
- `git fetch origin` ; `git rev-parse origin/main` = `a9e33d81315ba6c50fb881d00943d678330f5029` ; sinon STOP.

## Mission
Branche `fix/reglages-motif-date` depuis `origin/main`, worktree `.claude/worktrees/F01-M0013`. Correctif + tests ci-dessus (sortie collée). Diff total ≤ 300 lignes (sinon passer en N2 et le dire).
**Relecture N1** : un sous-agent FRAIS relit le diff (une passe) et écrit `vault/revues/2026-10-18-R011-reglages-motif-date.md` (frontmatter fermé par `---` : EXACTEMENT `verdict: GO|RESERVE`, `tip: <sha 40 du tip>`, `niveau: N1`). Seul un test rouge bloque ; le reste = issue GitHub.
Si GO : merge selon `.claude/skills/orchestration-bureau/references/gabarits.md` §9 mode direct (lu en entier ; rapport committé dans le scratch avant le `ff-only`), build/tests rejoués sur le scratch, push, `git ls-remote origin refs/heads/main` collé, worktrees retirés.
Preuve d'écran impossible → « non vérifié à l'écran » + checklist fondateur (3 gestes : Réglages › Mes soumissions, ce qu'il doit voir).

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : rapport `## Rapport M0013` **dans ce fichier** (en tête 5 lignes max en français simple) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (non committés) → commit vault ciblé sur `main`, push, `ls-remote` collé → footer (gabarit §4) → **`statut: reponse-disponible` EN DERNIER GESTE**.

## Rapport M0013

En français simple : la section « Mes soumissions » affiche maintenant le motif de modération d'une photo refusée ou acceptée, et une date relative (« il y a 1 j ») au lieu de la date brute. Le correctif est mergé sur `main` (`e14e7db`) et poussé. Une chose n'est pas vérifiée : l'affichage à l'écran (voir la checklist en bas).

- Préconditions : `origin/main` = `a9e33d8`, garde OK. Worktree `.claude/worktrees/F01-M0013`, branche `fix/reglages-motif-date`.
- Cause confirmée (preuve rouge, sortie réelle) : `ISO8601DateFormatter()` sans options renvoie `nil` sur `2026-10-17T14:03:35.035649+00:00` et sur `…35.035+00:00` ; `relativeDate` renvoyait donc la chaîne brute. Le motif (`review_notes`, décodé dans `Services/SupabaseService.swift:330`) n'était affiché nulle part.
- Correctif (`a05ca65`, 4 fichiers, 57 lignes) :
  - `App/SettingsView.swift` : `ISODateParser` (fonction pure, fraction tronquée à 3 chiffres, avec ou sans fraction, `Z` ou offset). `rowBody` reçoit un `note` ; la soumission photo passe `review_notes` si son statut n'est pas `pending`. Date illisible : `—`.
  - `fr.lproj` / `en.lproj/Localizable.strings` : `"Motif : %@"` (FR) / `"Reason: %@"` (EN).
  - `CHANGELOG.md` : entrée « Corrigé » dans 1.3.0 et ligne des notes App Store FR. Version inchangée (1.3.0 build 9).
- Tests exécutés (sortie collée) :
  - Harnais `swiftc` hors dépôt, extrait du vrai fichier, sur la base puis sur le scratch fusionné : `TOUS LES TESTS PASSENT` (6 décimales = 35 ms exacts, 3 décimales = 35 ms, 2 décimales = 30 ms, offset +02:00 = Z = +00:00, invalide et vide = nil, normalisation identité sans fraction).
  - Build Release iOS (`xcodebuild … CODE_SIGNING_ALLOWED=NO build`) : `** BUILD SUCCEEDED **` sur le worktree et sur le scratch fusionné. Aucun avertissement dans `SettingsView.swift`.
- Relecture N1 (sous-agent frais, une passe) : `verdict: GO`, `tip: a05ca6525af5065266c009f65616fb0b8c98a096`, `niveau: N1`. Rapport `vault/revues/2026-10-18-R011-reglages-motif-date.md`, vérifié (une ligne `verdict`, une ligne `tip`). Aucun test rouge. Trois remarques, transformées en issue (aucun nouveau tour) : https://github.com/malikkaraoui/boites-a-livres-ios/issues/18.
- Merge (gabarits §9, mode direct) : scratch `F01-M0013-merge` ; `git merge --no-ff a05ca65` → `abec8d8` ; rapport R011 committé dans le scratch → `e14e7db` ; `ff-only` depuis la racine (`a9e33d8..e14e7db`) ; `git push origin main`. `git ls-remote origin refs/heads/main` : `e14e7db6efc07d30164a4016f722110ae9a48f73`. Branche `fix/reglages-motif-date` poussée : `a05ca6525af5065266c009f65616fb0b8c98a096`.
- Nettoyage : scratch retiré ; worktree F01-M0013 retiré avec `--force` après `cmp` (copie non suivie identique au rapport committé).
- Non fait, et pourquoi :
  - Lignes de scellé (`verifier-rendu.mjs`) : sans objet, le script n'existe pas dans le dépôt.
  - Soumissions de boîtes et demandes de suppression : `BoxSubmissionRecord` et `DeletionRequestRecord` n'ont pas de `review_notes` ; l'ajouter touche `Services/SupabaseService.swift`, zone critique interdite pour ce mandat. STOP propre, à reprendre en N3 si voulu. Le champ `reason` des demandes de suppression est le motif de l'utilisateur, pas une modération.
  - Le fichier `vault/echanges/F01.md` reste non committé (fichier d'échange ; l'orchestrateur l'archive).
- Remarques R011 (issue #18) : le tiret `—` est en dur (il touche aussi boîtes, avis, suppressions) ; un motif fait uniquement d'espaces s'afficherait « Motif :   » ; pas de test versionné du parseur.

### Preuve d'écran : non vérifié à l'écran

Aucune capture réelle : pas de simulateur ni d'appareil dans cette session, et aucune écriture Supabase n'est permise. L'axe UX ne peut donc pas être GO à l'écran.

Checklist fondateur (sur un build du commit `e14e7db`) :
1. Ouvrir Réglages › Mes soumissions, avec une photo déjà refusée et commentée côté modération.
2. Vérifier que sous la ligne « Photo · Boîte #… — Refusée » apparaît « Motif : <commentaire> » en petit texte gris.
3. Vérifier que la date affichée est relative (« il y a 1 j »), et jamais `2026-10-17T…`.

Footer :

M0013
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         INTEGRATED
PROJECT STATUS      INTEGRATED
