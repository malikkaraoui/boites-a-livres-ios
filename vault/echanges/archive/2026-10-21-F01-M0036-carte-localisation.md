---
date: 2026-10-21
tags: [localisation, carte, alerte-proximite, build-17]
session: F01
mandat: carte-localisation-un-ecran-alerte-100m
mandat_id: M0036
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0036
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-21T18:47:13+0200
---

# F01 / M0036 — Écran « Localisation » : carte sur un seul écran, déplacement ≤ 100 m, alerte à 100 m activée par défaut ; build 17 sur l'iPhone de Malik

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question, les options et ton choix motivé, puis les rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne par une commande plus simple ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (règle du fondateur : Haiku medium partout, doublage compris). **N3** : `LocationService`/`Info.plist`/`project.pbxproj`/`project.yml` et la logique de localisation sont des zones critiques.

## Décisions du fondateur (21/10/2026, retours terrain, verbatim)
- 18:19 « Je trouve que c'est pas assez clair, il faut y ajouter une map » ; 18:20 « Comme quand on contredit la localisation » ; « Elle est zoomé déjà de base / On déplace juste la boîte si besoin / Et sinon on valide / Simplement ».
- 18:44 « tu ne peux pas modifier de +100m la position de la boîte à livres comme ça on s'assure que t'es sur place ».
- 18:45 « Passe à 100 m alors parce que c'est vrai que sur le terrain j'ai un petit peu de mal à le déclencher » (rayon de la notification de proximité).
- 18:45 « Et passe par défaut ce réglage parce que aujourd'hui par défaut il est pas actif les notifications proche d'une boîte à livres ».
- 18:45 « Lance les issues nécessaires, lance les mandats nécessaires ».
- Toujours valables : rien vers Apple sans « OK Apple » ; aucune vérification ajoutée côté base (décision du 19/10) ; Haiku medium.

## Interdits permanents
**Aucun geste git en écriture à la racine du dépôt** (ni merge, commit, push, stash, reset, checkout, add à la racine ; seul `git fetch origin` est permis) : la racine est laissée telle quelle (`main` local `5f51d13` divergent, fichiers du harnais modifiés). Tout se fait dans les worktrees du mandat. **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`. **Aucune écriture Supabase, aucun changement de schéma. Aucun appel à Apple** (ni `make release`, ni `release-check`, ni archive, ni TestFlight). Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/main` = `739cbf67b877e09719a3ea8cb1b9861871c63d96` ; `git rev-parse origin/docs/notes-1.3.0` = `10c4477380f687277ba16eff4e835f1712ee4dee`.
2. `git ls-remote origin refs/heads/feat/carte-localisation` vide ; `.claude/worktrees/F01-M0036` absent.

## Mise en place
`git worktree add -b feat/carte-localisation .claude/worktrees/F01-M0036 origin/docs/notes-1.3.0` (la branche part des notes de version validées, elles-mêmes sur `origin/main`). Tout le travail se fait dedans.

## Issue
Ouvre une issue GitHub (`gh issue create`) « Localisation : carte sur un seul écran, déplacement ≤ 100 m, alerte à 100 m activée par défaut » qui recopie les décisions verbatim ci-dessus ; cite son numéro dans les commits (`#N`). Ne la ferme pas (pas de merge dans ce mandat).

## Travail (état actuel lu sur `origin/main`)
Fichiers : `Views/Components/LocationUpdateSheet.swift` (384 lignes ; `enum Kind { confirm, move }`, boutons « Oui, elle est bien là » / « Non, elle est ailleurs », la carte n'existe qu'en mode `move`, ~l.219), `Models/BookBox.swift` (`LocationRules`, l.180-215), `Services/ProximityAlertService.swift`.

1. **Un seul écran.** Supprime le choix Oui/Non. La carte (même composant et même rendu que le mode `move` actuel : zoomée d'office, repère central, adresse en dessous, « Centrer sur ma position ») est **toujours** affichée, centrée au départ **sur la position actuelle de la boîte** (`box.lat`, `box.lng`), point bleu de l'utilisateur visible. Un seul bouton « Envoyer ».
   - Repère **non déplacé** par l'utilisateur = **confirmation** : envoi exactement comme l'actuel `case .confirm` (source `gps`, mêmes règles : précision ≤ 10 m, téléphone à ≤ `presenceMeters` de la boîte).
   - Repère **déplacé** (glissement de la carte ou « Centrer sur ma position ») = **nouvelle position** : envoi exactement comme l'actuel `case .move` (source via `LocationRules.source`, précision ≤ 50 m, téléphone à ≤ `presenceMeters`).
   - Le texte d'aide dit simplement : laisse le repère sur la boîte et envoie ; si elle est ailleurs, déplace la carte.
   - Aucun changement de payload, d'endpoint ni de champ envoyé au serveur.
2. **Déplacement ≤ 100 m.** `LocationRules.moveMaxMeters` : 500 → **100**. Au-delà : bouton grisé + texte « Tu ne peux pas déplacer la boîte de plus de 100 m. ».
3. **Rayon de la notification : 100 m, présence inchangée.** Aujourd'hui `proximityMeters = 50` sert À LA FOIS au rayon des régions (`ProximityAlertService` l.74) et à la présence (`LocationUpdateSheet` `nearEnough`). Sépare : `alertRadiusMeters = 100` (régions surveillées, journal de diagnostic) et `presenceMeters = 50` (envoi depuis l'écran Localisation, inchangé). Remplace tous les usages de `proximityMeters` en conséquence ; plus aucun usage ambigu.
4. **Alerte activée par défaut.** `ProximityAlertService.isEnabled` lit `UserDefaults.bool` (faux si clé absente). Nouveau comportement : clé absente = **activée** ; seul un « désactiver » explicite de l'utilisateur la coupe (la clé à `false` reste respectée). Ne déclenche **aucune** demande d'autorisation au démarrage à froid : la demande « Toujours » passe par le chemin existant (l.41-43), au premier moment où l'app la demande déjà aujourd'hui ; documente au rapport quand elle apparaît réellement pour un nouvel utilisateur. Si ce n'est pas faisable sans nouvelle demande d'autorisation au lancement : STOP propre avec les options.
5. **Textes** : mets à jour tout texte de l'app qui dit « 50 m » pour l'alerte ou « désactivée par défaut ». Puis `release-notes/fr-FR.txt` et `release-notes/en-US.txt`, **uniquement** ces corrections factuelles : « build 16 » → « build 17 » ; « (désactivée par défaut, » → « (activée par défaut, » / « (off by default, » → « (on by default, » ; « à moins de 50 m d'une boîte » → « à moins de 100 m d'une boîte » / « within 50 m of a box » → « within 100 m of a box ». Rien d'autre dans ces fichiers ; aucun point ni tiret en début de ligne (`grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).
6. **Version 17** : comme le commit `fb07563` (M0023) : `project.yml` `CURRENT_PROJECT_VERSION: 17`, `project.pbxproj` aligné de la même façon, `CHANGELOG.md` « Build 17 ». `MARKETING_VERSION` reste 1.3.0.
7. **Tests** : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; logique pure hors dépôt (`swiftc` avec le vrai `Models/BookBox.swift`) : repère à 99/100/101 m (actif/actif/grisé), présence 49/51 m, rayon d'alerte = 100, clé absente = activée, clé `false` = désactivée, clé `true` = activée ; `node --test scripts/release/asc.test.mjs` vert. Preuve d'écran : captures simulateur de l'écran Localisation (repère non déplacé, repère déplacé < 100 m, repère > 100 m grisé) dans `vault/revues/captures-M0036/` ; impossible → le dire, axe UX non GO, checklist fondateur.
8. Commits ciblés (écran ; règles + alerte ; textes et notes ; version), push `feat/carte-localisation` + `git ls-remote` collé. Tip = `T`.
9. **Doublage N3** : `R031` (relu dans `state.json` `next_revue_id` ; s'il diffère, prends sa valeur et dis-le). Sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`, tout le diff `origin/main..T`. Vérifie chaque décision ci-dessus point par point (fichier:ligne), aucun changement de payload, aucune nouvelle demande d'autorisation au lancement, présence toujours 50 m, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base $(git merge-base origin/main T)` collé. Rapport `vault/revues/2026-10-21-R031-carte-localisation.md`, frontmatter fermé : une ligne `verdict:`, une ligne `tip:` (sha 40), une ligne `niveau: N3`. Réserve prouvée par un test rouge → un correctif + re-doublage en chaîne (R suivant) ; 2e réserve de même classe → STOP. Remarques → issues GitHub. Rapport committé sur la branche + push + `ls-remote` collé.
10. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi), depuis un worktree détaché sur le tip GO : build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates`, `xcrun devicectl device install app --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A …`, lancement, `device info apps` → `1.3.0 17` collé. Injoignable : le dire (pas un STOP). Pas d'installation sans GO.
11. Retire tous les worktrees du mandat (`git worktree remove`, `prune`).

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0036` dans ce fichier (5 lignes max en français simple ; puis preuves ; puis 4 gestes de test terrain pour le fondateur) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne **`M0036`** et pas `M0036` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0036

- Écran Localisation unique : une carte centrée sur la boîte, sans choix Oui/Non. Repère laissé sur la boîte = confirmation ; repère déplacé = nouvelle position.
- Déplacement limité à 100 m (avant 500 m) : bouton grisé et message au-delà.
- Alerte de proximité : rayon 100 m, activée par défaut. La présence pour proposer une position reste à 50 m.
- Build 17. Branche `feat/carte-localisation` poussée (tip `fa15939`), relecture R031 GO, **non fusionnée** (pas de merge vers `main`).
- Non faits : captures simulateur et installation sur l'iPhone de Malik (appareil injoignable).

**Décisions à trancher par le fondateur** : (1) alerte « désactivée » affichée aux utilisateurs sans « Toujours » (issue #36) ; (2) les paragraphes de remerciement des notes, dont la mention d'une faille signalée par une personne nommée, viennent de la base `docs/notes-1.3.0` : à valider avant publication.

### Preuves

- Garde : `origin/main` = `739cbf67`, `origin/docs/notes-1.3.0` = `10c44773`, branche distante absente. Garde passée.
- Issues : #34 (mandat), #35, #36, #37 (remarques R031, converties en issues).
- Commits : `aae6fe3` écran et règles ; `2c33fcf` réglage ; `af9301e` notes ; `a9e4be7` version ; `fa15939` rapport R031.
- `git ls-remote origin refs/heads/feat/carte-localisation` → `fa159395238d5ee2f09151912a7b5a40e7ce8d77 refs/heads/feat/carte-localisation`.
- Build : `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → `** BUILD SUCCEEDED **`.
- `node --test scripts/release/asc.test.mjs` → 17 tests, 17 pass, 0 fail.
- Logique pure (`swiftc` avec le vrai `Models/BookBox.swift`) → 18 contrôles, 0 échec : repère 99/100/101 m, présence 49/51 m, rayon 100, clé absente = activée, `false` = désactivée, `true` = activée, précision et source.
- Budget : `pre-commit --controle a9e4be71 --base 739cbf67` → 4 OK, 0 ATTENTION, 0 BLOQUE.
- Non vérifié : captures simulateur (non produites), installation iPhone : `xcrun devicectl list devices` → « iPhone de Malik » `unavailable`.

### Gestes de test terrain (fondateur)

1. Ouvrir une boîte à moins de 50 m, bouton « Localisation » : la carte est centrée sur la boîte, il n'y a plus de Oui/Non. Envoyer sans bouger = confirmation.
2. Glisser la carte : moins de 100 m = bouton actif ; au-delà = bouton grisé et « Tu ne peux pas déplacer la boîte de plus de 100 m. ».
3. Réglages › Localisation : bascule ON par défaut. Sans « Toujours », observer le message d'alerte « désactivée » (issue #36).
4. Précision entre 10 et 50 m : un simple effleurement de la carte bascule-t-il en « repère déplacé » ? (issue #37)

Scellé : non applicable (mandat sans test de non-régression rouge→vert).

---

M0036
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌ (volontaire : pas de merge dans ce mandat)
Main push           ❌ (volontaire)
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
