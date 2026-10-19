---
date: 2026-10-19
tags: [publication, app-store-connect, issue-33]
session: F01
mandat: release-controles-avant-envoi
mandat_id: M0028
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0028
branche: fix/release-controles-avant-envoi
niveau: N3
derniere_maj: 2026-10-19T23:23:19+0200
---

# F01 / M0028 — `make release` : tous les contrôles Apple AVANT l'archive et l'envoi du build (issue #33)

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin.

Modèle : Haiku 5.5 medium. N3. Doublage par sous-agent FRAIS, même modèle.

## INTERDIT ABSOLU
**Aucun envoi de build, aucune écriture sur App Store Connect** (ni version, ni notes, ni soumission). Seules des requêtes **GET** réelles sont permises. Jamais de `make release CONFIRMER=OK-APPLE`. Ne jamais afficher ni committer la clé `.p8` ou un jeton.

## Le défaut (issue #33, remarque R023 ; décision du fondateur 19/10 23:22 « corrige ça rapidement »)
`make release` (`Makefile` + `scripts/release/asc.mjs`, lis `gh issue view 33` et `vault/revues/2026-10-19-R023-publication-app-store.md`) envoie le build **avant** de vérifier l'état des versions sur App Store Connect.

## Correctif attendu (rien d'autre)
Une étape `preflight` (lecture seule) exécutée **en premier**, avant toute archive ou envoi ; un seul échec = arrêt immédiat, message clair, code ≠ 0, rien lancé :
1. clé acceptée par Apple ;
2. aucune version de l'app dans un état d'attente ou de revue (`WAITING_FOR_REVIEW`, `IN_REVIEW`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_APP_STORE`, `PENDING_APPLE_RELEASE`, et tout état équivalent listé par la doc Apple que tu cites) — lecture **paginée complète** ;
3. `MARKETING_VERSION` > version en ligne ; numéro de build > dernier build reçu ;
4. `release-notes/fr-FR.txt` présent, non vide, ≤ 4000 caractères.
`make release-check` affiche aussi ce verdict de `preflight`. L'ordre final de `make release CONFIRMER=OK-APPLE` : garde OK-APPLE → preflight → archive → envoi → suite inchangée. Mets à jour `scripts/release/README.md` (remplacement, pas ajout).

## Garde (tout écart = STOP)
1. `git fetch origin` ; `git rev-parse main origin/main` = deux fois `8e94a2dc4fb47e370d847b180e8f29f849a0e4b4`.
2. `git status --short` racine : exactement `M vault/echanges/F01.md`, `M vault/echanges/F02.md`, `?? .claude/worktrees/` et des non suivis sous `vault/echanges/`.

## Mission 0 (racine, `main`, vault seul)
`git add -- vault/echanges/archive/2026-10-19-F01-M0027-publication-app-store.md`, commit `docs(vault): reconciliation orchestrateur -- archive M0027`, push `main` + `git ls-remote origin refs/heads/main` collé.

## Déroulé
1. Branche `fix/release-controles-avant-envoi` depuis `origin/main`, worktree `.claude/worktrees/F01-M0028`. Commit référencé `#33`. Push + `ls-remote` collé. Tip = `T`.
2. Tests : `node --test scripts/release/asc.test.mjs` vert, avec nouveaux cas : version « en revue » sur la 2e page ⇒ refus avant toute archive ; notes vides ⇒ refus ; ordre des étapes vérifié (l'archive n'est jamais appelée si le preflight échoue). Témoin rouge sur `origin/main`, vert sur `T`. `make release` sans confirmation ⇒ refus (sortie collée). `make release-check` réel (lecture) ⇒ sortie collée, sans secret.
3. **Doublage N3 R025** (`next_revue_id` relu) : sous-agent FRAIS, worktree détaché lecture seule ; vérifie l'ordre (aucun chemin n'archive ni n'envoie avant un preflight réussi), la pagination, la garde OK-APPLE, aucun secret, zéro dépendance ; budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base $(git merge-base origin/main T)` collé. `vault/revues/2026-10-19-R025-release-preflight.md`, frontmatter fermé : une ligne `verdict:`, une ligne `tip:` (sha 40), une ligne `niveau: N3`. Réserve prouvée → un correctif + R026 en chaîne, sinon STOP.
4. Si GO : merge gabarit §9 mode direct (`.claude/skills/orchestration-bureau/references/gabarits.md`, lu en entier). Push `main` + `ls-remote` collé. Ferme #33 par commentaire (sha). Retire les worktrees.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'appelle Apple en écriture ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Interdits
Jamais `sleep`, tâche de fond vivante, `stash`, `reset --hard`, `checkout -- .`, `update-ref`, `--no-verify`, `push --force`. `git add` ciblé. Aucune dépendance ajoutée.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN, dans l'ordre : `## Rapport M0028` (5 lignes max en français simple, puis preuves) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (non committés ; `next_revue_id` avancé) → commit vault ciblé + push + `ls-remote` collé → footer de statut (gabarit §4, `M0028`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0028

En français simple : le préflight App Store Connect est en place. `make release` lance d'abord une vérification en lecture seule (clé acceptée, aucune version en revue, numéros, notes) et s'arrête avant toute archive si elle échoue. Mergé sur `main` (`816b807`). Rien n'a été publié, aucun envoi, aucun appel en écriture à Apple.

- Premier doublage R025 (tip `0c9f78c`) : BLOQUE. `publish` n'avait plus `app` après le préflight ; reproduit (`app is not defined` à l'étape traitement). Correctif `8833713` avec test de chemin complet ; doublage R026 sur `8833713` : GO.
- Merge `a7ba1c9` (`--no-ff`) dans un scratch, 17/17 tests verts sur le résultat ; rapports R025 (`7dc134b`) et R026 (`816b807`) ; `ff-only` à la racine ; `git push origin main`.
- Issue #33 : commentaire posté, issue non fermée : les remarques 2 et 4 restent ouvertes.
- Écarts au mandat : le GO est R026 (R025 est BLOQUE) ; le message du commit `8833713` cite « R024 » à tort ; `links.next` avec jeton Bearer non traité (remarque 2, hors périmètre) ; liste des états d'attente non vérifiée contre l'énumération Apple (la page de doc n'a renvoyé que son titre).
- Non vérifié : le déclenchement réel de `make release CONFIRMER=OK-APPLE` (interdit par le mandat) ; seule la garde OK-APPLE est testée.

Preuves :
- Garde : `git rev-parse main origin/main` = `8e94a2d` (deux fois) ; `git status --short` conforme.
- Mission 0 : `a60a07e` poussé ; `git ls-remote origin refs/heads/main` = `a60a07e`.
- `node --test scripts/release/asc.test.mjs` : `tests 17`, `pass 17`, `fail 0`, sur `8833713` et sur le merge `a7ba1c9`.
- Témoin rouge, chemin complet, avant correctif : `arrêt à l'étape « traitement » : app is not defined`.
- Témoin rouge sur `origin/main` : `SyntaxError: ... does not provide an export named 'checkNotes'` (preuve faible : erreur d'import, pas un test de comportement).
- `make release` sans confirmation : `Refus : make release exige CONFIRMER=OK-APPLE exactement. Aucune action lancée.`, `make: *** [release] Error 1`.
- `make release-check` (lecture, code 0) : App « Boîtes à livres », version en ligne 1.2.0, dernier build reçu 5, `Contrôles OK : version 1.3.0 (build 16)`, `Préflight OK : version à créer, … notes 927 caractères`. Sortie filtrée, aucun secret.
- Budget : `controle-instructions : 4 fichier(s) … 4 OK, 0 ATTENTION, 0 BLOQUE`, code 0, sur `8833713`.
- `git ls-remote origin refs/heads/fix/release-controles-avant-envoi` = `883371330521ca1581d4c30781d94d1a9a64f959`.
- Worktrees de la session retirés ; ceux des autres fenêtres non touchés.

M0028
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         INTEGRATED
PROJECT STATUS      INTEGRATED
