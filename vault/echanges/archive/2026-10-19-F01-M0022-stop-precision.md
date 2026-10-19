---
date: 2026-10-19
tags: [build-14, localisation, proximite, photo, 1.3.0]
session: F01
mandat: build-14-localisation-v2
mandat_id: M0022
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'opus' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0022
branche: feat/build-14
niveau: N3
derniere_maj: 2026-10-19T18:30:34+0200
---

# F01 / M0022 — Build 14 : localisation temps réel, validation manuelle, invitation photo, diagnostic des alertes (+ #29, #30, #31)

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question que tu aurais posée, les options que tu voyais et celle que tu aurais choisie avec sa raison, puis applique les rituels de fin. Un STOP propre est un rendu valable ; une question laisse un mandat mort. Vaut aussi pour une demande d'autorisation d'outil : sans contournement, STOP propre.

Modèle : opus (`conception_critique`) : chemins critiques (`LocationService`, `AddBoxViewModel`, `Info.plist`…), N3.

## Interdits permanents
- Jamais de `sleep`, jamais de tâche de fond vivante à la sortie ; `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`.
- Git : `git add` ciblé, jamais `-a`/`-A` ; jamais `stash`/`reset --hard`/`checkout -- .` à la racine ; jamais de rebase ; jamais `--no-verify`, jamais `push --force`.
- **AUCUNE écriture en production Supabase** (base ou stockage) : lecture seule, tests sur données simulées. Aucune clé dans un fichier suivi, un log ou le rapport.
- **Aucune soumission App Store / TestFlight.**
- Commits : heredoc terminé par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3)
(1) lecture/recherche/doublage = agents FRAIS (jamais `fork`) ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, ni ne tue un autre agent ; (3) tout rapport de sous-agent VÉRIFIÉ (fichier:ligne) avant livrable ; (4) après incident : git status/diff/log/reflog d'abord ; (5) ATTENDRE le retour de tous avant le premier rituel de fin (jamais `sleep` ni sondage) ; échec = STOP propre.

## Retours terrain du fondateur (19/10, 17:57-18:05, build 13 sur iPhone) — ils font foi
1. Aucune alerte en passant près d'une boîte ; une alerte est arrivée plus tard (18:01). Il soupçonne le réglage iOS « Plan dans les alertes selon le lieu » (non prouvé ; aucune API ne le lit).
2. Écran « La boîte est-elle bien ici ? » : position **figée à ± 14 m**, aucune actualisation en marchant autour de la boîte. Cause probable relevée par l'orchestrateur : `Services/LocationService.swift:38` `distanceFilter = 50` jamais levé par `beginPrecisionUpdates()` (l.58-61). À PROUVER puis corriger. Exigence : **temps réel, sans lésiner** sur cet écran (`kCLLocationAccuracyBest` ou mieux, `kCLDistanceFilterNone`, affichage mis à jour à chaque position), retour au réglage économe à la fermeture.
3. « À 20 m près » : pouvoir **valider l'emplacement à la main** quand la précision ne descend pas sous 10 m.
4. Après « Oui / Non », **proposer d'ajouter une photo** (mise en avant si la boîte n'en a pas).
5. Écran « Merci ! » : **contenu centré** (icône, titre, texte, bouton).
Décisions du fondateur : feu vert build 14 le 19/10 à 17:59 (« Feux vert »), contenu ci-dessus et ci-dessous.

## Garde
`git fetch origin` ; `git rev-parse origin/main` = `c2565f7b8f18b504abe7a0452df26da4ca448f86` ; sinon STOP. Branche `feat/build-14` depuis `origin/main`, worktree `.claude/worktrees/F01-M0022`.

## Mission 0
Racine sur `main` : `git add -- vault/echanges/archive/2026-10-19-F01-M0020-build-13-localisation.md` (et tout fichier non suivi sous `vault/echanges/archive/` ou `vault/reprise/`, listés explicitement), commit `docs(vault): reconciliation orchestrateur -- archive M0020`, push + `ls-remote`.

## A. Écran de localisation (`Views/Components/LocationUpdateSheet.swift` + `LocationService`)
1. Position temps réel (point 2). Preuve : cause fichier:ligne, puis test de logique (ou simulateur avec `xcrun simctl location ... start` sur un trajet) montrant que la précision affichée change.
2. Seuils : envoi direct à ≤ 10 m (inchangé). Entre 10 m et 50 m : bouton « Placer le repère moi-même » qui ouvre la carte à pin déplaçable (comme `move`), envoi autorisé, `source = manual`, `accuracy_m` = précision réelle. Au-delà de 50 m : envoi impossible, message clair. (Choix de l'orchestrateur sur « à 20 m près » ; le dire au rapport.)
3. Après réponse Oui/Non puis envoi réussi : écran « Merci ! » **centré** + bouton « Ajouter une photo » vers le circuit photo existant (mis en avant si la boîte n'a pas de photo, discret sinon) + « Fermer ».
4. Aucune colonne non accordée à `anon` dans l'insert `location_updates` (inchangé).

## B. Alertes de proximité (`Services/ProximityAlertService.swift`)
1. Après chaque (ré)enregistrement des régions, `requestState(for:)` : si déjà **dans** une région et non bloquée par l'anti-répétition 30 j → même notification qu'à l'entrée (une seule fois). Explique au rapport ce que ça change pour le test du fondateur.
2. **Journal local des alertes** (sur le téléphone seulement, rien envoyé au serveur) : enregistrement des régions (heure, nombre), entrée/état « inside » (heure, id boîte, distance, précision), notification envoyée ou bloquée (raison). Visible dans Réglages › section « Diagnostic des alertes » (lecture, bouton « Effacer »), 200 lignes max.

## C. Issues GitHub `malikkaraoui/boites-a-livres-ios` (`gh issue view 29` / `30` / `31`, lire EN ENTIER, commentaires compris)
- **#29** : fenêtre Annuler / Réglages si localisation ≠ « Toujours », position non exacte, actualisation en arrière-plan coupée ou notifications refusées (tout ce qu'iOS permet de lire ; le réglage « Plan dans les alertes » ne se lit pas, ne pas l'inventer).
- **#30** : pastille d'état Bon/Moyen/Mauvais + invitation avis/photo (règles de l'issue : sans avis ou avis > 30 j, photo d'abord, carte verte par défaut). Libellés : ceux proposés dans l'issue.
- **#31** : nouvelle boîte : photo obligatoire + présence ≤ 50 m (`ViewModels/AddBoxViewModel.swift`, aujourd'hui sans contrôle de distance).
Commits référencés `#29`/`#30`/`#31` ; fermer par commentaire après merge (sha).

## Version
`CURRENT_PROJECT_VERSION` 13 → **14** (`project.yml` + `project.pbxproj`, toutes occurrences), `MARKETING_VERSION` reste 1.3.0. `CHANGELOG.md` « Build 14 ».

## Tests et preuves
- Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`, sortie collée ; `make test` si la cible existe.
- Logique pure testée (`swiftc` hors dépôt si pas de cible de test) : seuils 10/50 m et source `manual`, requestState→notification + anti-répétition, journal borné à 200, règles #30, garde 50 m de #31.
- Captures simulateur réelles avant/après (écran localisation avec précision qui évolue, Merci centré + bouton photo, diagnostic, fenêtre #29, pastille #30, ajout de boîte #31) dans `vault/revues/captures-M0022/`. Impossible → checklist fondateur (gabarit §10).

## Déroulé
1. Un commit par bloc (A, B, #29, #30, #31, version) ; push, `ls-remote` collé.
2. **Doublage N3 R017** (`next_revue_id` relu) par sous-agent FRAIS, worktree détaché lecture seule sur le tip : rejoue build/tests, vérifie les 5 retours terrain et les 3 issues, refait les captures, budget `pre-commit --controle` collé. `vault/revues/2026-10-19-R017-build-14.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → correctif + re-doublage en chaîne (R018), une fois, sinon STOP.
3. Si GO : merge `gabarits.md` §9 mode direct (lu en entier). Push, `ls-remote` collé.
4. **Installation sur l'iPhone du fondateur** : worktree détaché sur le nouveau `origin/main` → `make device` → fin de sortie collée ; `xcrun devicectl device info apps --device <UDID> --bundle-id com.malikkaraoui.boitesalivresapp` → `1.3.0 14`, collé. iPhone injoignable → le dire (pas un STOP). `git worktree remove` ensuite.

## Conditions STOP
Garde fausse ; cause du point 2 introuvable ; insert qui exigerait une colonne non accordée ou une migration ; réserve N3 non résolue en un tour ; conflit de merge hors fichiers générés.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : `## Rapport M0022` (5 lignes max, français simple, puis preuves ; checklist de test terrain pour le fondateur en 3-5 gestes) → `vault/reprise/F01.md` → `events.jsonl` + `state.json` (non committés) → commit vault ciblé + push + `ls-remote` → footer de statut (gabarit §4, `M0022`) → **`statut: reponse-disponible` EN DERNIER GESTE**.

## Rapport M0022

**STOP propre, aucun code modifié.** Le point A.2 exige d'envoyer `accuracy_m` = précision réelle entre 10 et 50 m. La base de production le refuse : contrainte `location_updates_accuracy_ck` = `accuracy_m` entre 0 et 10 m. Le faire demanderait une migration, ce qui est une condition STOP du mandat. Rien d'autre n'a été commencé (blocs A, B, #29, #30, #31 et version intacts) : il faut d'abord trancher ce point.

### Question que j'aurais posée
Pour « Placer le repère moi-même » entre 10 et 50 m de précision, que met-on dans `accuracy_m` ?

### Options
1. **Migration additive** (mandat dédié, feu vert du fondateur, écriture prod) : élargir la contrainte, par ex. `accuracy_m between 0 and 50` (ou `<= 10` sauf `source = 'manual'` ≤ 50). Respecte le mandat à la lettre, mais bloque le build 14 jusqu'à l'application.
2. **`accuracy_m = null` pour `source = manual`** quand la précision dépasse 10 m (la contrainte l'accepte ; `gps_accuracy_ck` ne vise que `source = 'gps'`). Aucune migration. L'admin voit `manual`, mais pas la précision réelle.
3. Plafonner `accuracy_m` à 10 : rejeté, ce serait une fausse donnée.

**Choix que j'aurais fait : option 2 dans le build 14**, plus une issue pour l'option 1 plus tard. Raison : débloque tout le build aujourd'hui sans écrire en prod. `source = manual` signale déjà à l'admin que le repère a été placé à la main. La précision réelle n'est perdue que pour ces envois-là.

### Preuves
- Garde : `git fetch origin` puis `git rev-parse origin/main` = `c2565f7b8f18b504abe7a0452df26da4ca448f86` (conforme).
- Mission 0 : commit `ac93d96` `docs(vault): reconciliation orchestrateur -- archive M0020` (13 archives, chemins listés un par un), poussé. `git ls-remote origin refs/heads/main` = `ac93d96d44c5ff930e5acc75fa8ddd2259a9fa99`.
- Contrainte en production, lue en **lecture seule** (`select … from pg_constraint`, projet `tszxcbsdjdtecoikxuwu`) : `location_updates_accuracy_ck CHECK ((accuracy_m IS NULL) OR ((accuracy_m >= 0) AND (accuracy_m <= 10)))`. Même texte dans `BoitesALivres/supabase/migrations/20261019120000_location_updates.sql` (« précision GPS : 10 m au plus »). Le trigger `location_updates_guard` accepte déjà un `confirm` à ≤ 50 m de la boîte et un `move` à ≤ 500 m : seule la précision bloque.
- Cause du point 2 (écran figé à ± 14 m), relevée pour le prochain mandat : `Services/LocationService.swift:38` `manager.distanceFilter = 50`, et `beginPrecisionUpdates()` (l.58-61) ne change que `desiredAccuracy`. iOS ne livre donc aucune nouvelle position tant que le téléphone n'a pas bougé de 50 m, et la précision affichée reste figée. Lecture de code, pas encore prouvée par test (aucun code écrit).
- Worktree `F01-M0022` créé puis retiré, branche `feat/build-14` supprimée (aucun commit, elle pointait sur `ac93d96`). Rien de poussé hors vault.
- Vault : commit `6d2240f` (`vault/reprise/F01.md`), poussé ; `git ls-remote origin refs/heads/main` = `6d2240f3ddbde0e1e8e3bd6764d5ab8c9cd85aba`. `events.jsonl` et `state.json` mis à jour (hors git).
- Aucune écriture Supabase, aucune soumission App Store ou TestFlight, aucun sous-agent lancé.

### Checklist fondateur
Sans objet : rien de nouveau à installer. Le build 13 reste sur l'iPhone.

Pour relancer : reposer M0022 (ou un nouveau mandat) en précisant l'option retenue pour `accuracy_m`. Si c'est l'option 1, il faut d'abord un mandat de migration.

M0022
Implementation      ❌
Tests               ❌
Commit              ❌
Branch push         ❌
Review              ❌
Merge main          ❌
Main push           ❌
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
