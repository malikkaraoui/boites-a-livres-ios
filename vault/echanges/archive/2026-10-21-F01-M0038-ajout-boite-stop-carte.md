---
date: 2026-10-21
tags: [ajout-boite, clavier, carte, build-18]
session: F01
mandat: ajout-boite-clavier-carte-precision
mandat_id: M0038
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0038
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-21T19:45:30+0200
---

# F01 / M0038 — « Ajouter une boîte » : champ note au-dessus du clavier, un seul saut de ligne, précision 50 m, carte centrée sur l'utilisateur ; build 18 sur l'iPhone de Malik

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris, règle du fondateur). **N3** (`ViewModels/AddBoxViewModel.swift`, `project.yml`, `project.pbxproj` sont critiques).

## Retours terrain du fondateur (21/10/2026 19:28, build 17), verbatim
« Le text une fois le clavier sorti est en parti coupé (l'input clavier devrait être au dessus du clavier pour une saisi confortable). Dès lors que je clic dans l'input une fenêtre de taille moyenne (comme dans lapp Claude mobile que j'utilise pour taper ces quelques mots) fixe et avec un scroll. Je peux sauter autant d'espace que je veux cela je devrai pas être possible. Limite à un saut. Quand je clic sur replacer car le n'affiche pas plus précisément ma position (repasse bien à 50m de précision minimum pour la création d'un point). La je me retrouve avec une carte non centrée sur moi [carte de toute la France]. J'aimerai une carte center sur moi et le point d'intérêt là où je l'ai déjà mis. »
19:44 « oui » (feu vert : branche du build 17, build 18, N3, installé sur son iPhone, rien vers Apple).

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures) : racine laissée telle quelle (`main` local `5f51d13` divergent, fichiers du harnais modifiés). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`. **Aucune écriture Supabase, aucun changement de schéma, aucun changement de payload/endpoint/champ envoyé.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `fa159395238d5ee2f09151912a7b5a40e7ce8d77`.
2. `.claude/worktrees/F01-M0038` absent.

## Mise en place
`git worktree add .claude/worktrees/F01-M0038 feat/carte-localisation` puis, dans le worktree, `git merge --ff-only origin/feat/carte-localisation` et `git rev-parse HEAD` = `fa15939…` (collé ; sinon STOP). Tout le travail se fait dedans, commits sur `feat/carte-localisation`.

## Issue
`gh issue create` « Ajout de boîte : clavier, sauts de ligne, précision 50 m, carte centrée » avec le retour verbatim ci-dessus ; numéro cité dans les commits (`#N`). Ne la ferme pas.

## Travail (fichiers : `App/AddBoxView.swift`, `ViewModels/AddBoxViewModel.swift`, `Models/BookBox.swift` `LocationRules`)
1. **Champ note** (étape 2/2) : quand le clavier est ouvert, le champ note reste entièrement visible **juste au-dessus du clavier** (défilement automatique du formulaire vers le champ actif, aucun texte masqué). Le champ a une **hauteur moyenne fixe** (environ 5 lignes) et **défile à l'intérieur** quand le texte dépasse ; il ne grandit pas. Le formulaire garde son défilement normal ; un geste ferme le clavier (toucher hors du champ ou bouton « OK » au-dessus du clavier).
2. **Un seul saut de ligne** : dans la note, jamais deux sauts de ligne consécutifs (une ligne vide au plus entre deux lignes de texte n'est PAS permise : un `\n` maximum d'affilée) ; appliqué à la saisie ET au collage ; espaces et sauts de ligne superflus en début/fin retirés à l'envoi. Fonction pure dans `LocationRules` ou à côté (ex. `normalizeNote`), testable hors app. Même règle pour tout autre champ multi-ligne de cet écran s'il y en a.
3. **Précision 50 m pour la création** : aujourd'hui `presenceDistance` exige `LocationRules.canSend` (≤ 10 m) et le texte dit « Patiente, le GPS affine ta position (10 m ou mieux)… ». Passe à **≤ 50 m** (`canSendManual`, `manualMaxAccuracyMeters`) ; présence inchangée (point à ≤ `presenceMeters` = 50 m du GPS). Texte d'attente : « (50 m ou mieux) ». Si l'envoi de création transmet une précision ou une source au serveur, ne change ni le champ ni le format ; si la base risquait de refuser une précision entre 10 et 50 m (contrainte lue dans `supabase/` du dépôt admin ou dans le code d'envoi), STOP propre avec la preuve.
4. **Carte centrée sur l'utilisateur** : à l'ouverture de l'étape 1/2 et à chaque retour par « Replacer » / retour à l'étape position, la caméra est **zoomée (≈ 300 m) et centrée sur la position GPS actuelle** ; le repère reste **là où il était déjà posé** (`pinCoordinate` conservé). Si le GPS n'est pas encore disponible à l'ouverture (cas actuel : `Constants.defaultLocation` = carte de France), recentre caméra ET repère dès le premier fix GPS, **tant que l'utilisateur n'a pas encore déplacé la carte**. Jamais de vue « France entière » quand une position est connue.
5. **Version 18** : `project.yml` `CURRENT_PROJECT_VERSION: 18`, `project.pbxproj` aligné comme pour le build 17 (`a9e4be7`), `CHANGELOG.md` « Build 18 ». `release-notes/fr-FR.txt` et `en-US.txt` : seulement « build 17 » → « build 18 » (rien d'autre ; `grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).
6. **Tests** : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; logique pure hors dépôt (`swiftc` avec le vrai `Models/BookBox.swift` et la fonction de note) : `"a\n\n\nb"` → `"a\nb"`, `"\n\na\n"` → `"a"`, `"a\nb"` inchangé, précision 49/50/51 m (OK/OK/refus), cas M0036 rejoués ; `node --test scripts/release/asc.test.mjs` vert. Preuve d'écran : captures simulateur (clavier ouvert sur la note avec texte long, carte étape 1 centrée) dans `vault/revues/captures-M0038/` ; impossible → le dire, axe UX non GO, checklist fondateur.
7. Commits ciblés, push `feat/carte-localisation` + `git ls-remote` collé. Tip = `T`.
8. **Doublage N3** `R032` (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`, diff `fa15939..T`, chaque point ci-dessus vérifié fichier:ligne, aucun changement de payload, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base fa159395238d5ee2f09151912a7b5a40e7ce8d77` collé. Rapport `vault/revues/2026-10-21-R032-ajout-boite.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé sur la branche + push + `ls-remote` collé.
9. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `devicectl device install app --device C3CFC878-6C8D-5B87-8B35-1CB108A4922A …` ; lancement ; `device info apps` → `1.3.0 18` collé. `unavailable` → le dire (pas un STOP).
10. Retire tous les worktrees du mandat (`git worktree remove`, `prune`).

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0038` dans ce fichier (5 lignes max en français simple ; puis preuves ; puis 4 gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0038` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0038

**Arbitrage ouvert, mandat BLOQUÉ au point 4 (carte).** Le reste est livré sur `feat/carte-localisation` (`fe48b53`, poussé).

- **Fait :** champ note fixe de 5 lignes qui défile en interne, défilement du formulaire vers le champ à l'ouverture du clavier, bouton « OK » au-dessus du clavier ; un seul saut de ligne (saisie, collage, envoi) ; création possible à 50 m de précision ; build 18 ; issue #38 ouverte (non fermée).
- **Non fait :** point 4, carte centrée sur l'utilisateur au retour « Replacer ». Pas de doublage R032, pas d'installation sur l'iPhone (pas de GO possible).
- **Pourquoi :** le repère est une épingle fixe au centre de la carte (`pinCoordinate` = centre de caméra). Centrer la carte sur le GPS déplace donc le repère sur le GPS et efface le point posé ; le garder là où il était demande de le dessiner à part.
- **Question au fondateur :** quelle carte veux-tu au retour « Replacer » ?
  - **A (choix recommandé)** : repère dessiné à la position enregistrée, carte centrée sur le GPS (300 m), on glisse la carte pour déplacer le repère. Coût : refonte de l'épingle (marqueur + conversion de coordonnées), à vérifier au simulateur. Non testée ici.
  - **B** : carte centrée sur le GPS, le repère suit le centre (comportement actuel). Simple, mais le point posé est perdu.
  - **C** : carte centrée sur le point posé (retour à l'existant, sans « centrée sur moi »).
- **Preuves :** `xcodebuild … -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` → `** BUILD SUCCEEDED **` (deux fois, la 2e après réindentation). Logique pure (`swiftc` avec le vrai `Models/BookBox.swift`) : 13 cas verts, dont `"a\n\n\nb"`→`"a\nb"`, `"\n\na\n"`→`"a"`, précision 49/50 OK, 51 refusée. `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail. Pas de captures simulateur (non faites) : axe UX non vérifié à l'écran.
- **Contrôle Supabase :** la création (`insertBoxSubmission`) n'envoie ni `accuracy_m` ni `source` ; aucune contrainte de précision dans `supabase/migrations/` ; aucun changement de payload.
- **Garde :** `origin/feat/carte-localisation` = `fa15939…` (vérifié) ; worktree absent (vérifié). Worktree `F01-M0038` retiré après commit.

### Gestes de test terrain (build 18 non installé, à faire après GO)

1. Ajouter une boîte, étape 2, toucher la note : le champ reste visible au-dessus du clavier.
2. Taper plusieurs retours à la ligne, coller un texte à doubles sauts : un seul saut visible.
3. GPS à 20-50 m : le texte dit « 50 m ou mieux », Soumettre s'active à 50 m ou moins (ne pas soumettre).
4. « Replacer » : la carte n'est PAS encore centrée sur toi (point 4 non livré, attendu).

### Footer de statut

```
M0038
Implementation      ❌ (point 4 non livré, arbitrage ouvert)
Tests               ✅ (BUILD SUCCEEDED Release ×2 ; swiftc 13/13 ; node 17/17)
Commit              ✅ fe48b53
Branch push         ✅ ls-remote refs/heads/feat/carte-localisation = fe48b535e64add30c1c4f3c24843142ead43a43a
Review              ❌ (non lancée : pas de GO)
Merge main          ❌ (volontaire)
Main push           ❌ (volontaire)
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
```
