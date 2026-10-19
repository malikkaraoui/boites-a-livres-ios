---
date: 2026-10-18
tags: [photos, carrousel, ios, 1.3.0]
session: F01
mandat: photos-validees-carrousel-ios
mandat_id: M0010
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0010
branche: fix/photos-validees
niveau: N3
derniere_maj: 2026-10-18T15:51:33+0200
---

# F01 / M0010 — iOS : afficher les photos VALIDÉES, ne plus montrer les photos en attente (1.3.0 build 9)

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question que tu aurais posée, les options que tu voyais et celle que tu aurais choisie avec sa raison, puis applique les rituels de fin. Un STOP propre est un rendu valable et laisse l'orchestrateur décider ; une question laisse un mandat mort. Vaut aussi pour une demande d'autorisation d'outil : n'insiste pas ; contourne par une commande plus simple (lecture seule, `git show`, `git -C`, chemin explicite) ; sinon STOP propre.

## Interdits permanents
- Jamais de `sleep`, jamais de tâche de fond vivante à la sortie ; `rm -rf` seulement sous forme gardée `"${VAR:?}/${SOUS:?}"`.
- Git : `git add` ciblé, jamais `-a`/`-A` ; jamais `stash`/`reset --hard`/`checkout -- .` à la racine ; jamais de rebase ; jamais `--no-verify`.
- **AUCUNE écriture en production Supabase** (base ou stockage) dans ce mandat : lecture seule, et tests sur données simulées.
- Ne jamais afficher ni écrire une clé (service ou anon) dans un fichier suivi, un log ou le rapport.
- Signature des commits : message en heredoc terminé par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3, verbatim)
(1) lecture/recherche parallèle = agents FRAIS (jamais `fork`) ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, ni ne tue un autre agent ; (3) tout rapport de sous-agent est VÉRIFIÉ (fichier:ligne recontrôlés) avant le livrable ; (4) après tout incident : git status/diff/log/reflog AVANT toute autre action ; (5) ATTENDRE LE RETOUR DE TOUS les sous-agents avant le premier rituel de fin — jamais `sleep` ni sondage ; échec de l'un = STOP propre.

## Garde de précondition
- `git fetch origin` ; `git rev-parse origin/main` doit valoir `5da85f22ddc32a32c5ecddf6b32057f88606054a` (avant ta Mission 0) ; sinon STOP.

## Mission 0 — scope git strict, À LA RACINE, sur `main`
1. `git checkout main` puis `git branch --show-current` → `main`, sinon STOP.
2. `git status --short`.
3. **Harnais v1.6.6** (posé par `harnais equiper` le 18/10 à 15:48, non committé) : committer EN PATHSPEC EXPLICITE les seuls fichiers du harnais modifiés : `.claude/skills/orchestration-bureau/SKILL.md`, `.claude/skills/orchestration-bureau/references/gabarits.md`, `config/harnais.json`, `scripts/harnais-hooks/README.md`, `scripts/harnais-hooks/pre-push` (et tout autre fichier sous `.claude/skills/orchestration-bureau/` ou `scripts/harnais-hooks/` modifié par la pose ; un `*.canon-*` éventuel : le citer au rapport, ne pas le committer). **Avant ce commit**, dans `config/harnais.json`, mettre `modeles.bareme.defaut` et `modeles.bareme.realisation_standard` à `"claude-haiku-5-5 --effort medium"` (décision du fondateur, 18/10/2026 15:47 : « haiku de base 5.5 medium effort »). Message : `chore(harnais): pose du harnais v1.6.6 + bareme haiku par defaut`.
4. Vault : `git add` des seuls fichiers sous `vault/echanges/archive/`, `vault/reprise/`, `vault/revues/`, `vault/decisions/`, `vault/lecons/` (JAMAIS `vault/echanges/*.md` hors archive, JAMAIS `vault/runtime/`), commit `docs(vault): reconciliation orchestrateur -- archives au 18/10`.
5. Push `main`, coller `git ls-remote origin refs/heads/main`.

## Contexte — diagnostic vérifié (dépôt admin, mandat M0027 du 18/10)
- `SupabaseService.listPhotos` (l.128-156) construit le carrousel avec `book_boxes.photo_url` + la liste du stockage `boites-photos` sous `"<boxId>/"`. Or : une photo envoyée par l'app est posée sous `<boxId>/<uuid>.jpg` **en attente de modération** ; à la validation, l'admin la copie sous `approved/<boxId>/slot-N-…`, l'inscrit dans la table `book_box_photos` (box_id, slot 1..3, url) et efface la source.
- Conséquences en production : les photos validées n'apparaissent jamais (sauf si elles sont devenues `photo_url`) ; les photos **en attente** sont montrées publiquement ; la limite de 3 compte les photos en attente et la `photo_url`, pas les slots validés.
- `BookBoxSheet.swift` (aperçu carte) n'affiche que `photo_url` ; si elle est morte : carré gris. Une réparation des données côté base est menée en parallèle (dépôt admin) ; l'app doit malgré tout résister à une URL morte.

## Mission (branche `fix/photos-validees` depuis `origin/main` après Mission 0, worktree `.claude/worktrees/F01-M0010`)
0. Vérifier en lecture (curl, clé anon de `App/Constants.swift`, jamais affichée) : `GET <supabaseURL>/rest/v1/book_box_photos?box_id=eq.14183&select=slot,url&order=slot.asc` → coller code + corps. **Si 401/403 ou `[]`** : continue le code quand même (la politique de lecture est traitée côté admin), et dis-le en tête du rapport.
1. `listPhotos` : source = `book_box_photos` de la boîte (ordre des slots), puis `photo_url` en tête **seulement si** elle n'est pas déjà dans la liste ; dédoublonnage par URL. **Supprimer la lecture du préfixe `<boxId>/`** (plus aucune photo en attente montrée). Échec de la requête : retomber sur `photo_url` seule.
2. Carrousel / plein écran : une photo dont le chargement échoue est **retirée** de l'affichage (pas de carré gris si une autre photo existe) ; carré gris seulement s'il ne reste rien.
3. Aperçu carte (`BookBoxSheet`) : si `photo_url` échoue, charger la première photo de `book_box_photos` de la boîte ; sinon masquer le bloc image.
4. Limite « Maximum 3 photos » : compter les **slots validés** (`book_box_photos`), plus la `photo_url` seulement si elle n'y figure pas ; jamais les photos en attente.
5. Version : `CURRENT_PROJECT_VERSION: 9` (reste `MARKETING_VERSION: 1.3.0`) dans `project.yml` et le `.pbxproj` régénéré/mis à jour comme le fait le dépôt ; `CHANGELOG.md` section `[1.3.0]` : « Build 9 », entrée « Corrigé » en français simple ; notes App Store FR (fichier existant du dépôt) mises à jour.
6. Tests unitaires (cible de tests existante) : ordre et dédoublonnage, `photo_url` morte, aucune photo, limite. `xcodebuild test` ou la cible `make` du dépôt : coller la sortie. Build Release compilé (sans archive ni envoi).
7. Preuve d'écran : impossible sans iPhone → axe UX « non vérifié à l'écran » + **checklist fondateur** (3 à 5 gestes, sur son iPhone, boîte #14183 et une boîte à 1 photo : ce qu'il doit voir).

## Conditions STOP
- Garde fausse ; build ou tests rouges non réparables dans le mandat ; tout geste d'envoi App Store / TestFlight (interdit).

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : rapport `## Rapport <mandat_id>` dans ce fichier (en tête : **5 lignes max en français simple** pour le fondateur) → `vault/reprise/F01.md` → événements dans `vault/runtime/events.jsonl` + `state.json` (écrits, jamais committés) → commit(s) ciblés, vault compris → push de la branche + `git ls-remote origin refs/heads/<branche>` collé → footer de statut (gabarit §4) → **`statut: reponse-disponible` EN DERNIER GESTE**.
- Ne merge PAS dans `main` : niveau N3, un doublage indépendant suivra.

## Rapport M0010

**En bref :**
1. Les photos en attente ne sont plus montrées : carrousel, plein écran, aperçu carte et limite de 3 ne lisent plus que les photos validées.
2. Code fait, build Release OK, branche `fix/photos-validees` @ `66123e8` poussée. Pas vérifié à l'écran (pas d'iPhone dans la session).
3. Le projet n'a aucune cible de tests (`testTargets: []`) : la fusion des photos est vérifiée par un harnais hors dépôt (6 cas verts), pas la vue.
4. Bloqué : le push de `main` est refusé par la garde `pre-push` (le commit d'harnais touche des fichiers hors `vault/`). Rien n'a été forcé ; 2 commits restent en local sur `main`.
5. Ton arbitrage : faire passer l'harnais par une branche + doublage + merge `--no-ff`, et décider si une cible de tests est créée.

**Précondition** : `origin/main` = `5da85f22ddc32a32c5ecddf6b32057f88606054a`, branche `main`. OK.

**Lecture Supabase** (GET seul, clé anon non affichée) : `book_box_photos?box_id=eq.14183` → HTTP 200, 3 lignes :
- slot 1 : `…/boites-photos/14183/1.jpg`
- slot 2 : `…/boites-photos/14183/2.jpg`
- slot 3 : `…/boites-photos/approved/14183/slot-3-FF4F8D50-….jpg`

Point à vérifier côté admin : les slots 1 et 2 pointent hors du dossier `approved/`, comme le slot 3. Je n'ai pas tranché si ce sont des photos validées.

**Mission 0 — commits**
- `26d68f3` `chore(harnais): pose du harnais v1.6.6 + bareme haiku par defaut` : local sur `main`, non poussé. `modeles.bareme.defaut` et `realisation_standard` = `claude-haiku-5-5 --effort medium`, selon la décision du 18/10 15:47.
- `c86a208` `docs(vault): reconciliation orchestrateur -- archives au 18/10` : local sur `main`, non poussé (7 fichiers sous `vault/echanges/archive/`).
- Push `main` : REFUSÉ par `scripts/harnais-hooks/pre-push` (« sur main, seuls passent les merges avec rapport de doublage GO et les commits qui ne touchent que vault/ »). Non contourné (`--no-verify` interdit). `git ls-remote origin refs/heads/main` = `5da85f22ddc32a32c5ecddf6b32057f88606054a` (inchangé).

**Mission — code** (worktree `.claude/worktrees/F01-M0010`, branche `fix/photos-validees` depuis `origin/main`)
- `SupabaseService.listPhotos` : lit `book_box_photos` (ordre des slots), `photo_url` ajoutée en tête si absente, dédoublonnage par URL (fonction pure `PhotoList.merge` dans `Models/BookBox.swift`). Le préfixe `<boxId>/` n'est plus listé. Échec de la requête : `photo_url` seule.
- `PhotoCarousel` et `FullScreenPhotoViewer` : une photo dont le chargement échoue est retirée (état local) ; le carré gris ne reste que s'il ne reste rien. `CachedAsyncImage` gagne un `onFailure` optionnel (défaut `nil`, appels existants inchangés).
- `BookBoxSheet` : si `photo_url` échoue, charge la première photo validée ; si rien ne charge, le bloc image est masqué.
- `DetailViewModel.refresh` : remplace `photos` même si la liste est vide (avant, une liste vide était ignorée et l'ancienne restait).
- Limite « Maximum 3 » : inchangée dans `DetailView`/`DetailViewModel` ; elle compte désormais `photos`, qui ne contient que les slots validés et `photo_url` si elle n'y figure pas.
- Version : `CURRENT_PROJECT_VERSION` 8 → 9 dans `project.yml` et `project.pbxproj` (2 occurrences). `MARKETING_VERSION` reste `1.3.0`.
- `CHANGELOG.md` : `[1.3.0]` « Build 9 », entrée « Corrigé », note App Store FR complétée.
- Commit `66123e8` `fix(photos): afficher les photos validees seulement, build 9 [M0010]`, poussé sur `fix/photos-validees`. `git ls-remote origin refs/heads/fix/photos-validees` = `66123e859df2a44c284b16b7ebfb1500a192cdd8`, égal à `HEAD`.

**Vérifications exécutées**
- Build Release : `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → `** BUILD SUCCEEDED **` (log : `/private/tmp/claude-501/-Users-malik-Documents-Boites-a-livres-BoitesALivresNative/66c7a54b-5c27-4fce-9112-3a129bffe8b0/scratchpad/build.log`). Le message CoreSimulator « out of date » est environnemental et ne touche pas un build device générique.
- Tests : `make test` / `xcodebuild test` non lancés : `testTargets: []`, aucune cible à exécuter. Substitut : `PhotoList.merge` extrait tel quel de `BookBox.swift` et compilé avec `swiftc` (`scratchpad/h/main.swift`) : 6 cas PASS (ordre, fallback absente en tête, fallback déjà présente sans déplacement, aucune photo, fallback seule, doublon). Sortie : `ALL PASS`, exit 0.
- Requête réseau : le même chemin que `listPhotos` a été appelé en lecture (200, 3 lignes, ci-dessus). L'appel complet de l'app n'a pas été exécuté.
- Garde du préfixe : `grep` sur `SupabaseService.swift` ne trouve plus `prefix` de stockage ni `storage/v1/object/list`.

**Ce qui n'est pas vérifié** : aucun geste à l'écran, donc le retrait d'une photo morte et le masquage de l'aperçu carte restent à valider sur iPhone (axe UX « non vérifié à l'écran »).

**Hors périmètre, signalé et non corrigé**
- `MapScreen.swift:177,226,244` et `ListView.swift:190-193` utilisent `photo_url != nil` pour la hauteur de feuille et l'icône ; ils ne tiennent pas compte d'une `photo_url` morte.
- Les photos en attente restent dans le stockage sous `<boxId>/` ; leur nettoyage relève du dépôt admin.

**Décisions prises à ta place (à relire)**
- Retrait des photos mortes par état local dans chaque vue, pas dans `DetailViewModel`.
- Pas de cible de tests créée : cela modifie la structure du projet, hors mandat.
- Signature des commits : `Co-Authored-By: Malik & Claude`, selon le mandat (et non la ligne Haiku du rappel de session).

**Checklist fondateur** (sur iPhone, build depuis `fix/photos-validees`, pas encore sur `main`)
1. Boîte #14183, ouvrir le détail : le carrousel montre les photos validées (3 attendues) et aucune photo en attente.
2. Boîte #14183, ouvrir le plein écran et glisser entre les photos : aucun carré gris.
3. Une boîte à 1 photo validée : le carrousel montre 1 photo ; le bouton d'ajout affiche « 1/3 publiées ».
4. Boîte avec 3 photos validées : « Maximum 3 photos atteint » s'affiche.
5. Carte : toucher une boîte dont `photo_url` est morte : l'aperçu montre la première photo validée, ou pas de bloc image.

**Suite** : doublage indépendant N3 de `fix/photos-validees`, puis merge `--no-ff` ; tout cela attend la résolution du push de `main` (point 4).

M0010
Implementation      ✅
Tests               ❌ (aucune cible de tests dans le projet ; harnais hors dépôt verts, non équivalent)
Commit              ✅ (66123e8 sur fix/photos-validees ; 26d68f3 et c86a208 locaux sur main)
Branch push         ✅ (fix/photos-validees, ls-remote = 66123e8)
Review              ❌ (N3, doublage non lancé)
Merge main          ❌ (N3, interdit ici)
Main push           ❌ (refusé par pre-push)
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
