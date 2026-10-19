---
date: 2026-10-19
tags: [build-16, version-minimale, mise-a-jour-obligatoire]
session: F01
mandat: version-minimale-app
mandat_id: M0025
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0025
branche: feat/version-minimale
niveau: N3
derniere_maj: 2026-10-19T22:31:25+0200
---

# F01 / M0025 — Mise à jour obligatoire : l'app lit la version minimale et bloque en dessous (build 16, iPhone)

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Demande d'autorisation d'outil : sans contournement, STOP propre.

Modèle : Haiku 5.5 medium. Niveau N3 (`SupabaseService.swift`, `project.yml`, `project.pbxproj` sont critiques). Doublage par sous-agent FRAIS, même modèle.

## Interdits permanents
Jamais de `sleep`, de tâche de fond vivante à la sortie, de `stash`/`reset --hard`/`checkout -- .` à la racine, de rebase, de `--no-verify`, de `push --force`. `git add` ciblé. `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`. **Aucune écriture Supabase.** Aucune soumission App Store / TestFlight. Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Décision du fondateur (19/10/2026, 20:58-21:01)
« C'est moi qui gère la version minimale. » L'admin règle **version actuelle** et **version minimale** ; rien n'est compté, aucune remontée de version par l'app. L'app lit la version minimale et **bloque** en dessous avec une invitation à mettre à jour.

## Ce qui existe en production (appliqué par M0056 du dépôt admin, vérifié par l'orchestrateur le 19/10 à 22:30)
Table `public.app_config` : une ligne `id = 1`, colonnes `current_version`, `min_version` (texte `x.y.z`), `updated_at`. `anon` : **SELECT seulement**. Valeurs actuelles : 1.3.0 / 1.3.0.

## Ce que tu livres
1. Au lancement de l'app **et** à chaque retour au premier plan : lecture de `app_config` (`select min_version, current_version where id = 1`, client Supabase existant, clé anon), version de l'app = `CFBundleShortVersionString`.
2. Comparaison **numérique** par segment (1.10.0 > 1.9.9 ; segments manquants = 0). Fonction pure isolée, testée.
3. Si version de l'app < `min_version` : écran plein, **bloquant** (non fermable, pas d'accès au reste de l'app), titre « Mise à jour nécessaire », texte simple « Une nouvelle version de Boîtes à Livres est disponible. Mets à jour l'app pour continuer. », bouton « Mettre à jour » qui ouvre `https://apps.apple.com/app/id6768351762`. Style cohérent avec l'app (centré).
4. **Échec de lecture** (hors ligne, erreur, table absente, valeur illisible) : **ne jamais bloquer** ; journaliser et continuer. Le dire en commentaire dans le code.
5. Si la version minimale redescend sous la version de l'app (admin corrigé) : l'écran disparaît au prochain retour au premier plan.
6. Version : `CURRENT_PROJECT_VERSION` 15 → **16** (`project.yml` + `project.pbxproj`, toutes occurrences), `MARKETING_VERSION` reste 1.3.0 ; `CHANGELOG.md` « Build 16 ».

## Garde (tout écart = STOP)
1. `git fetch origin` ; `git rev-parse main origin/main` = deux fois `8210d6391cb9b2bd57489ac3ccf12a48ba48b1ba`.
2. `git status --short` racine : exactement `M vault/echanges/F01.md`, `M vault/echanges/F02.md`, `?? .claude/worktrees/` et des non suivis sous `vault/echanges/`. Rien d'autre.

## Mission 0 (racine, `main`, vault seul)
`git add -- vault/echanges/archive/2026-10-19-F01-M0024-alerte-vue-30-jours.md`, commit `docs(vault): reconciliation orchestrateur -- archive M0024`, push `main` + `git ls-remote origin refs/heads/main` collé. Ne committe ni `vault/echanges/F01.md` ni `F02.md`.

## Déroulé
1. Branche `feat/version-minimale` depuis `origin/main`, worktree `.claude/worktrees/F01-M0025`. Commits : logique + écran (1), version (2). Push + `ls-remote` collé.
2. Tests : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; logique pure testée (`swiftc` hors dépôt) : comparaisons (1.3.0 = 1.3.0 non bloqué ; 1.3.0 < 1.3.1 bloqué ; 1.10.0 > 1.9.9 ; « 1.3 » = « 1.3.0 » ; valeur illisible ⇒ non bloqué). Lecture réelle en base en **lecture seule** autorisée pour vérifier le format (`select` uniquement).
3. **Doublage N3 R020** (`next_revue_id` relu) : sous-agent FRAIS, worktree détaché lecture seule ; vérifie : jamais de blocage sur échec de lecture, comparaison numérique, écran non fermable, lien App Store, aucune écriture en base, version 16 ; budget `sh "$(git config core.hooksPath)/pre-commit" --controle <tip> --base $(git merge-base origin/main <tip>)` collé. `vault/revues/2026-10-19-R020-version-minimale.md`, frontmatter fermé : une ligne `verdict:`, une ligne `tip:` (sha 40), une ligne `niveau: N3`. Réserve prouvée → correctif + R021 en chaîne, une fois, sinon STOP.
4. Si GO : merge gabarit §9 mode direct (`.claude/skills/orchestration-bureau/references/gabarits.md`, lu en entier). Push `main` + `ls-remote` collé. Refus du hook : STOP.
5. **Installation sur l'iPhone du fondateur** : worktree détaché sur le nouveau `origin/main` → `make device` (fin collée) ; `xcrun devicectl device info apps --device <UDID> --bundle-id com.malikkaraoui.boitesalivresapp` → `1.3.0 16`, collé. iPhone injoignable → le dire (pas un STOP). Retire ensuite tous les worktrees de ce mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN, dans l'ordre : `## Rapport M0025` (5 lignes max en français simple, puis preuves ; 3 gestes de test pour le fondateur : avec minimale 1.3.0 l'app s'ouvre ; minimale 1.3.1 dans l'admin ⇒ écran bloquant au retour au premier plan ; remettre 1.3.0 ⇒ l'écran disparaît) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (non committés) → commit vault ciblé + push + `ls-remote` collé → footer de statut (gabarit §4, `M0025`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0025

**STOP en revue, rien mergé.** Build 16 codé et poussé ; le doublage R020 rend RÉSERVE : l'écran bloquant passe sous les modales déjà ouvertes. Décision fondateur requise avant merge.

- Branche `feat/version-minimale` poussée, tip `54b868f` (`4755455` logique + écran, `54b868f` version 16). Worktree `.claude/worktrees/F01-M0025` conservé.
- Build Release `generic/platform=iOS` : `** BUILD SUCCEEDED **`. Logique pure (`swiftc` hors dépôt) : 20/20 cas OK.
- Lecture réelle `app_config` (SELECT) : `[{"min_version":"1.3.0","current_version":"1.3.0"}]`, HTTP 200.
- **Décision à prendre** (détail dans `vault/revues/2026-10-19-R020-version-minimale.md`) :
  - **A (recommandée)** : écran dans une fenêtre UIKit dédiée, au-dessus des modales. Couvre le défaut ; à vérifier sur iPhone.
  - **B** : `fullScreenCover` racine. Ne couvre pas une modale déjà ouverte.
  - **C** : accepter la limite et la consigner.
- Après ton choix : correctif, R021, merge `ff-only`, `make device`, `devicectl` → `1.3.0 16`. Je ne lance rien tant que tu n'as pas tranché.

**Gestes de test (après installation, pas avant) :**
1. Avec `min_version` = `1.3.0` dans l'admin, ouvrir l'app : elle s'ouvre normalement.
2. Mettre `min_version` = `1.3.1`, revenir au premier plan : écran « Mise à jour nécessaire » bloquant.
3. Remettre `1.3.0` : au prochain retour au premier plan, l'écran disparaît.

**Preuves :** `git ls-remote origin refs/heads/feat/version-minimale` → `54b868fa29a9761cdcf384ee7f79486a0cd19bb0`. `git ls-remote origin refs/heads/main` → `6f25c121fab5cf1da66d611dd686f05e9cb970ec`. Vault commit `6f25c12` poussé. `vault/runtime/events.jsonl` : une ligne `CHECKPOINT` ajoutée. `vault/runtime/state.json` absent : non créé (je n'invente pas l'état ; `next_revue_id` = R021 à reporter quand il existe).

Note : `vault/echanges/F01.md` (ce fichier) et `F02.md` ont des modifications locales préexistantes ; je ne les ai pas committées.

M0025
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ❌
Merge main          ❌
Main push           ❌
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
