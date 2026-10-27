---
date: 2026-10-23
tags: [publication, app-store, ok-apple, 1.3.0, build-28]
session: F01
mandat: publication-app-store-1.3.0-build-28
mandat_id: M0058
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0058
branche: main
niveau: N1
derniere_maj: 2026-10-23T08:10:25+0200
---

# F01 / M0058 — Publication App Store : version 1.3.0, build 28 (« OK Apple » donné)

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium. Aucun code modifié, aucun commit de code.

## Décision du fondateur (23/10/2026), verbatim
08:07 « Build iPhone. Et si ok on envoie à Apple » ; build 28 installé et lancé (M0057, `1.3.0 28`) ; **08:09 « OK Apple »**. Les notes envoyées sont celles de `release-notes/fr-FR.txt` (validées le 21/10, « build 28 »). Le script n'envoie que le français : c'est connu et accepté pour cet envoi.

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add --detach`, `git worktree remove`, `git worktree prune` et lectures). Aucun commit de code, aucun push de code. Jamais de `sleep`, de tâche de fond vivante à la sortie. **Aucune écriture Supabase** (ne touche pas à `app_config.min_version`). **Ne jamais afficher ni copier le contenu de la clé `.p8`, ni un jeton signé.** Une seule exécution de `make release` : **jamais de relance** après une erreur (un état partiel est possible chez Apple : le rapport le décrit, l'orchestrateur décide).

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/main` = `0647239771e6b1823ff842e3c3764fd487e0408b`.
2. `git worktree add --detach .claude/worktrees/F01-M0058 0647239771e6b1823ff842e3c3764fd487e0408b` ; dans le worktree : `project.yml` `MARKETING_VERSION: 1.3.0` et `CURRENT_PROJECT_VERSION: 28` ; première ligne de `release-notes/fr-FR.txt` = `Version 1.3.0 (build 28)` (collés).
3. `test -f ~/.appstoreconnect/config.env` (sans l'afficher).

## Travail (dans le worktree)
1. `node --test scripts/release/asc.test.mjs` → fin collée (17 pass attendus). Rouge : STOP.
2. **`make release-check`** (lecture seule) : sortie collée en entier (filtrée de tout secret). Attendu : clé acceptée, version en ligne 1.2.0, aucune version en revue, « Contrôles OK : version 1.3.0 (build 28) », préflight OK. Tout autre verdict : STOP, rien d'autre lancé.
3. **`make release CONFIRMER=OK-APPLE`** une seule fois : sortie collée en entier (filtrée de tout secret), avec l'étape atteinte (préflight, archive, envoi, traitement, version, nouveautés, soumission). Erreur à une étape : STOP immédiat, message d'Apple et étape collés, **aucune relance**.
4. Après succès : `make release-check` une seconde fois (lecture) : sortie collée ; doit montrer la version 1.3.0 en attente de revue (`WAITING_FOR_REVIEW` ou équivalent) avec le build 28.
5. `git worktree remove --force .claude/worktrees/F01-M0058` ; `git worktree prune` ; `git worktree list` = racine seule (collé).
6. `vault/reprise/F01.md` mis à jour (publication soumise ou non, état Apple, heure) : commit vault ciblé sur `main` à la racine, push, `git ls-remote origin refs/heads/main` collé.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0058` dans ce fichier (3 lignes en français simple : soumis ou non, état chez Apple, prochaine étape) + preuves → `vault/runtime/events.jsonl` + `state.json` (jamais committés) → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0058` ; Review/Merge = N/A) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0058

- **Soumis ou non :** non. La version 1.3.0 (build 28) est créée et prête, mais la soumission à la revue a été refusée par Apple (HTTP 409) : rien n'est en revue.
- **État chez Apple :** version 1.3.0 en `PREPARE_FOR_SUBMISSION`, build 28 `VALID` ; 1.2.0 reste en ligne. Un état partiel existe, donc la version 1.3.0 est à reprendre, pas à recréer.
- **Prochaine étape :** ouvrir App Store Connect, lire la raison du 409 sur la version 1.3.0 (champs obligatoires ou exigence manquante), corriger à la main, puis décider de la relance. Aucune relance n'a été faite ici.

Preuves :
- Garde : `origin/main` = `0647239771e6b1823ff842e3c3764fd487e0408b` ; `project.yml` 1.3.0 / 28 ; notes `Version 1.3.0 (build 28)`.
- `node --test scripts/release/asc.test.mjs` : tests 17, pass 17, fail 0.
- `make release-check` (avant) : « Contrôles OK : version 1.3.0 (build 28), en ligne 1.2.0, dernier build reçu 5 » ; « Préflight OK ».
- `make release CONFIRMER=OK-APPLE` (une seule exécution) : archive OK ; `EXPORT SUCCEEDED` ; build 28 `VALID` (essai 5/40) ; étapes 4 et 5 OK ; étape 6/6 : `POST /v1/reviewSubmissionItems -> HTTP 409 : appStoreVersions ... is not in valid state` ; `make: *** [release] Error 1`.
- `make release-check` (après, lecture seule) : `Version 1.3.0 : PREPARE_FOR_SUBMISSION`, `Build 28 : VALID`. Son « ERREUR : build 28 non supérieur au dernier build reçu (28) » est attendu après un envoi réussi : ce n'est pas une faute.
- Reprise : `vault/reprise/F01.md`, commit `3b91f03`, poussé ; `git ls-remote origin refs/heads/main` = `3b91f03b326523905e27635d8d4fe6740c7ce702`.
- Worktree `.claude/worktrees/F01-M0058` conservé pour diagnostic (détaché à `0647239`, sans commit).

Notes :
- Le trousseau macOS a demandé une autorisation pendant l'archive ; le fondateur l'a acceptée, l'archive a ensuite réussi.
- Le mandat dit « soumission en 6/6 » : l'erreur vient après l'envoi, donc le build 28 est bien sur App Store Connect (non en revue).
- Aucun secret affiché : clé `.p8` et jetons jamais imprimés.

Décision à prendre (orchestrateur / fondateur) : corriger la version 1.3.0 dans App Store Connect puis relancer la soumission seule (sans relancer l'archive ni l'envoi), ou lancer un nouveau mandat dédié à la reprise.

Scellé : non applicable (aucun code modifié).

M0058
Implementation      N/A
Tests               ✅
Commit              ✅
Branch push         N/A
Review              N/A
Merge main          N/A
Main push           ✅
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
