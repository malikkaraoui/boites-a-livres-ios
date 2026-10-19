---
date: 2026-10-19
tags: [localisation, proximite, notification, build-13, 1.3.0]
session: F01
mandat: build-13-localisation
mandat_id: M0020
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0020
branche: feat/localisation
niveau: N3
derniere_maj: 2026-10-19T14:10:00+02:00
---

# F01 / M0020 — Build 13 : mise à jour de localisation + notification de proximité (+ issues #21, #22)

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question que tu aurais posée, les options que tu voyais et celle que tu aurais choisie avec sa raison, puis applique les rituels de fin. Un STOP propre est un rendu valable et laisse l'orchestrateur décider ; une question laisse un mandat mort. Vaut aussi pour une demande d'autorisation d'outil : n'insiste pas ; contourne par une commande plus simple (lecture seule, `git show`, `git -C`, chemin explicite) ; sinon STOP propre.

## Interdits permanents
- Jamais de `sleep`, jamais de tâche de fond vivante à la sortie ; `rm -rf` seulement sous forme gardée `"${VAR:?}/${SOUS:?}"`.
- Git : `git add` ciblé, jamais `-a`/`-A` ; jamais `stash`/`reset --hard`/`checkout -- .` à la racine ; jamais de rebase ; jamais `--no-verify`.
- **AUCUNE écriture en production Supabase** (base ou stockage) dans ce mandat : lecture seule, et tests sur données simulées.
- Ne jamais afficher ni écrire une clé (service ou anon) dans un fichier suivi, un log ou le rapport.
- Signature des commits : message en heredoc terminé par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3, verbatim)
(1) lecture/recherche parallèle = agents FRAIS (jamais `fork`) ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, ni ne tue un autre agent ; (3) tout rapport de sous-agent est VÉRIFIÉ (fichier:ligne recontrôlés) avant le livrable ; (4) après tout incident : git status/diff/log/reflog AVANT toute autre action ; (5) ATTENDRE LE RETOUR DE TOUS les sous-agents avant le premier rituel de fin — jamais `sleep` ni sondage ; échec de l'un = STOP propre.

## Pourquoi, et l'échéance
Le fondateur teste **ce soir sur le terrain** (iPhone réel, build installé) : il s'approche d'une boîte, l'app étant fermée, et doit recevoir la notification « La boîte est-elle bien ici ? », puis faire le parcours. Livrer un build 13 installé sur son iPhone est l'objectif ; mieux vaut un parcours simple qui marche qu'un parcours complet fragile.

## Sources qui font foi (à lire EN ENTIER avant de coder)
- Spec : `/Users/malik/Documents/Boites-a-livres/BoitesALivres/docs/specs/localisation-boites.md` (+ migration `…/BoitesALivres/supabase/migrations/20261019120000_location_updates.sql` : colonnes insérables par l'app, garde-fous du trigger, RPC `my_location_updates`). Ne JAMAIS envoyer une colonne non accordée à `anon` (`status`, `old_*`, `reviewed_at`, `review_notes`) : l'insert échouerait.
- Issues GitHub `malikkaraoui/boites-a-livres-ios` #21 (nombre de livres au clavier numérique) et #22 (aperçu de la fiche : 2 photos/2 points au lieu de 3, boîte #1639) : `gh issue view 21` / `22`.
- La table `location_updates` est appliquée en production en parallèle (autre mandat). Ne touche PAS à la base : aucun MCP Supabase, aucune écriture serveur hors ce que l'app envoie à l'exécution.

## Garde
- `git fetch origin` ; `git rev-parse origin/main` = `67d09b60e218f29515efb43fd88b5afee2d99985` ; sinon STOP. Branche `feat/localisation` depuis `origin/main`, worktree `.claude/worktrees/F01-M0020`.

## A. Parcours « Localisation » (depuis la fiche d'une boîte et depuis la notification)
Entrée : bouton « Localisation » dans la fiche détail (`BookBoxDetailView` ou équivalent, à recontrôler), actif seulement si l'utilisateur est à **≤ 50 m** de la position actuelle de la boîte (sinon grisé + « Approche-toi à moins de 50 m »). La présence est vérifiée **sur le téléphone uniquement**.
Écran :
1. Question « La boîte est-elle bien ici ? » → **Oui** (`kind = confirm`) / **Non, elle est ailleurs** (`kind = move`).
2. Précision GPS : indicateur 5 barres (≤ 5 m = 5, ≤ 10 m = 4, ≤ 20 m = 3, ≤ 50 m = 2, sinon 1) + texte « Précision : ± X m ». Envoi possible seulement à **≤ 10 m** (4-5 barres) ; sinon « Patiente, le GPS affine ta position… ». `CLLocationManager` en `kCLLocationAccuracyBest` **pendant cet écran seulement**.
3. `move` : carte avec un pin déplaçable, initialisé à la position GPS ; source = `gps`, ou `manual` si le pin a été déplacé, ou `photo` si une photo de la galerie avec EXIF a été choisie (seulement si le réglage EXIF est activé, cf. C). Adresse proposée par `CLGeocoder` (inverse, sur le téléphone) affichée sous la carte, mise à jour quand le pin bouge. L'utilisateur ne tape jamais de coordonnées.
4. Si la boîte n'a pas de photo : invitation « Ajoute une photo » vers le circuit photo existant (inchangé).
5. Envoi : insert dans `location_updates` (colonnes accordées seulement : `box_id, kind, lat, lng, address, city, postal_code, department, source, accuracy_m, device_token, platform`). `confirm` : position = position GPS courante. **La position de l'utilisateur n'est envoyée que comme position proposée de la boîte ; aucun autre champ de position.** Message de succès « Merci ! Ta proposition sera vérifiée par un administrateur. » ; erreur réseau / refus serveur (ex. 500 m dépassés, doublon `pending`) → message clair, pas de crash.
6. Anti-répétition **30 jours par boîte**, stockée sur le téléphone (`UserDefaults`), posée après un envoi réussi ET après un « Plus tard » sur la notification.

## B. Notification de proximité (app fermée)
- Permission « Toujours » : demandée **seulement** depuis un écran d'explication (Réglages › « Alerte près d'une boîte », interrupteur, désactivé par défaut) ; jamais au lancement. Clés `Info.plist` : `NSLocationAlwaysAndWhenInUseUsageDescription` (+ `NSLocationWhenInUseUsageDescription` existante), textes FR simples. N'ajoute `UIBackgroundModes: location` QUE si c'est prouvé nécessaire (la surveillance de régions n'en a normalement pas besoin — à vérifier dans la doc Apple, cite la source).
- Surveillance de régions `CLCircularRegion` rayon **50 m**, `notifyOnEntry`, **20 régions au plus** (limite iOS) : les 20 boîtes les plus proches **non bloquées par l'anti-répétition**, recalculées à chaque `significantLocationChange` (ou à chaque ouverture de l'app).
- À l'entrée : **notification locale** « 📚 Boîte à livres à côté — Est-elle bien ici ? » (identifiant = id de la boîte). Toucher la notification ouvre la fiche puis le parcours A (réutilise `DeepLinkRouter`, ne crée pas de second routeur). Action « Plus tard » → anti-répétition 30 jours.
- Ne rien envoyer au serveur à l'entrée de région.
- Batterie : aucune localisation continue en arrière-plan.

## C. Réglages
- Section « Localisation » : interrupteur « Alerte près d'une boîte » (B) ; interrupteur « Utiliser la position des photos (EXIF) » (désactivé par défaut).
- « Mes soumissions » : ajoute les propositions de localisation via la RPC `my_location_updates(p_device_token)` (statut En attente / Validée / Refusée + motif), dans la liste existante.

## D. Issues
- **#21** : nombre de livres saisissable au clavier numérique (`.numberPad` + bouton OK), − / + conservés, synchronisés, entier ≥ 0, borne max actuelle.
- **#22** : l'aperçu de la fiche affiche toutes les photos de la boîte (même liste et même ordre que la visionneuse plein écran) et autant de points que de photos. Cause à prouver (fichier:ligne) avant correction.
- Commits référencés `#21` / `#22` ; ferme-les par commentaire après merge (avec le sha).

## Version
`CURRENT_PROJECT_VERSION` 12 → **13** (`project.yml` + `project.pbxproj`, toutes occurrences), `MARKETING_VERSION` reste 1.3.0. `CHANGELOG.md` 1.3.0 « Build 13 » (Ajouté / Corrigé + notes App Store FR). **Aucune soumission App Store / TestFlight.**

## Tests
- Build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`, sortie collée.
- Logique pure testée hors dépôt (`swiftc`) : barres de précision, sélection des 20 régions (anti-répétition, tri par distance), anti-répétition 30 jours, construction du payload (aucune colonne interdite), seuil 50 m.
- Simulateur autorisé : position simulée (`xcrun simctl location`) pour capturer le parcours A et la notification (captures dans `vault/revues/captures-M0020/`).

## Déroulé
1. Implémentation par étapes, un commit par bloc (A, B, C, D, version) ; push, `ls-remote` collé.
2. **Doublage N3 R016** par un sous-agent FRAIS (jamais `fork`), worktree détaché lecture seule sur le tip : rejoue build/tests, vérifie contre la spec (aucune position utilisateur envoyée hors position proposée, colonnes accordées seulement, ≤ 10 m, 50 m, 20 régions, 30 jours, permission demandée seulement depuis Réglages), #21/#22. `vault/revues/2026-10-19-R016-localisation.md` (frontmatter fermé par `---` : EXACTEMENT `verdict: GO|RESERVE`, `tip: <sha 40>`, `niveau: N3`). Seul un test rouge, une fuite de position ou une colonne interdite bloque ; le reste = issue GitHub ; écran non vérifiable = checklist. Tu vérifies son rapport.
3. Si GO : merge `.claude/skills/orchestration-bureau/references/gabarits.md` §9 mode direct (lu en entier). Push, `ls-remote` collé.
4. **Installation sur l'iPhone du fondateur** : worktree détaché sur le nouveau `origin/main` → `make device` (UDID du `Makefile`) → fin de sortie collée ; `xcrun devicectl device info apps --device <UDID> --bundle-id com.malikkaraoui.boitesalivresapp` → `1.3.0 13`, collé. iPhone non joignable → le dire (pas un STOP). `git worktree remove` ensuite.

## Conditions STOP
Garde fausse ; build rouge non résolu ; doublage RESERVE ; toute écriture en base hors exécution de l'app ; tout envoi App Store / TestFlight ; un secret dans un fichier ou un log.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : rapport `## Rapport M0020` **dans ce fichier** (en tête 5 lignes max en français simple + **checklist du test terrain de ce soir**, étape par étape) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (non committés) → commit vault ciblé sur `main` (dont `vault/revues/captures-*`), push, `ls-remote` collé → footer (gabarit §4) → **`statut: reponse-disponible` EN DERNIER GESTE**.

## Rapport M0020

En français simple : la version 1.3.0 build 13 est mergée dans `main` et poussée (`c914ac7`). Elle contient le bouton « Localisation » sur la fiche, l'alerte de proximité (désactivée par défaut), la section Réglages, et les deux issues #21 (clavier pour le nombre de livres) et #22 (aperçu à 3 photos). **Elle n'est pas installée sur l'iPhone** : il était « unavailable » pendant la session. Et l'envoi d'une proposition renverra « service pas encore disponible » tant que la migration `location_updates` n'est pas appliquée en base.

- Garde : `origin/main` = `67d09b60e218f29515efb43fd88b5afee2d99985` à l'ouverture, conforme. Branche `feat/localisation` depuis `origin/main`.
- Commits : `51470e8` (#21, #22), `240da1c` (parcours, alerte, réglages), `9f9c343` (build 13). Le commit `240da1c` seul ne compile pas : il ne référence pas encore les deux nouveaux fichiers dans le `pbxproj` ; `9f9c343` les ajoute. Le tip `9f9c343` est donc la seule version à retenir.
- Build Release `generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO` : `** BUILD SUCCEEDED **`, sur le tip puis sur le résultat du merge.
- Tests de logique pure : compilés contre les vrais `Models/BookBox.swift` et `Models/BoxReview.swift`, 36 pass / 0 fail (relecteur) ; mes propres tests passés aussi (20 régions, anti-répétition 29/31 j, barres, journal, saisie des livres).
- Revue R016 (N3, sous-agent frais, lecture seule) : `verdict: GO`, `tip: 9f9c343bcd52b349743e68a82785116f4c7b0422`. Rapport : `vault/revues/2026-10-19-R016-localisation.md`. Constats non bloquants transformés en issues #23 à #28 (GitHub).
- Merge `--no-ff` `bf3838e`, rapport `c914ac7` dans le scratch, `ff-only` à la racine, `git push origin main` : `67d09b6..c914ac7`. `git ls-remote origin refs/heads/main` = `c914ac7ed3de66438542889b4964db2ba8c92937`.
- #21 et #22 : commentées avec le SHA, **non fermées**. Leur critère « testé sur téléphone réel » n'est pas rempli. Le mandat demandait de les fermer après merge ; je ne l'ai pas fait pour ne pas afficher un critère coché à tort.
- Écarts assumés :
  - Photo EXIF (réglage « Utiliser la position des photos ») : **non implémentée**, hors lot ce soir.
  - `UIBackgroundModes location` : non ajouté. Preuve Apple non tranchée (doc de régions muette, retours développeurs contradictoires). À trancher sur téléphone.
  - Les régions se calculent depuis le cache local des boîtes, pour ne rien envoyer au serveur. Conséquence : sans carte chargée une fois, pas de régions.
- Installation (étape 4) : **non faite**. `xcrun devicectl list devices` : « iPhone de Malik » = `unavailable`. Pas un STOP : à refaire dès que l'iPhone est branché et déverrouillé, avec `make device` puis `xcrun devicectl device info apps --device 00008101-001278EA36E9001E --bundle-id com.malikkaraoui.boitesalivresapp` (doit donner `1.3.0 13`).
- Non vérifié à l'écran : tout le parcours (GPS réel, notification à froid, permission « Toujours », clavier, aperçu). Aucune capture simulateur.

### Checklist du test terrain (à faire après installation)

1. **Aperçu (#22)** : ouvrir la fiche de la boîte #1639. L'aperçu doit montrer 3 points, comme la visionneuse (plein écran en touchant la photo).
2. **Livres (#21)** : Donner mon avis → toucher le nombre de livres → le clavier numérique s'ouvre ; taper 40 → « 40 » affiché ; bouton OK ferme le clavier ; − / + restent synchronisés.
3. **Réglages** : Réglages › Localisation › activer « Alerte près d'une boîte » → une explication s'affiche → Continuer → iOS demande « Toujours ». Sans accorder, la section affiche le message « autorise Toujours » et le bouton Ouvrir les Réglages.
4. **Parcours** : près d'une boîte (≤ 50 m), fiche → bouton « Localisation » actif (sinon grisé avec « Approche-toi… »). Répondre « Oui » : attendre 4 ou 5 barres (≤ 10 m), puis Envoyer. **Attendu tant que la migration n'est pas appliquée** : « Le service de localisation n'est pas encore disponible ».
5. **Notification** : app fermée (balayée), alerte activée, s'approcher d'une boîte déjà chargée sur la carte → notification « 📚 Boîte à livres à côté — Est-elle bien ici ? ». Toucher → la fiche s'ouvre avec le parcours. « Plus tard » → pas de nouvelle alerte pour cette boîte pendant 30 jours.

TASK STATUS et footer ci-dessous.

Mandat M0020
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         IN_PROGRESS
PROJECT STATUS      INTEGRATED
