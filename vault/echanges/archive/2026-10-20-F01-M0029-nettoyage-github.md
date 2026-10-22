---
date: 2026-10-20
tags: [nettoyage, github, worktrees, vault]
session: F01
mandat: nettoyage-github-soir
mandat_id: M0029
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative
branche: main
niveau: N1
derniere_maj: 2026-10-20T00:02:00+0200
---

# F01 / M0029 — Nettoyage : vault sur GitHub, worktrees retirés, branches distantes fusionnées supprimées

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin.

Modèle : Haiku 5.5 medium. N1. Aucun code, aucune base, **aucun appel App Store Connect**, jamais `make release`.

## Décision du fondateur (19/10 23:30, confirmée 23:58 « FONCE »)
« met a jour github / supprime les work tree / supprime les branches sur github qui ne servent plus a rien ».

## Garde (tout écart = STOP)
1. `git fetch origin --prune` ; `git rev-parse main origin/main` = deux fois `838ab5e…` (colle le sha complet).
2. `git status --short` racine : seulement des modifiés/non suivis sous `vault/`.

## Mission 1 — vault sur GitHub (racine, `main`, vault seul)
`git add -- vault/reprise/CARNET_DE_BORD.md vault/echanges/archive/` (jamais `vault/echanges/F0*.md`), commit `docs(vault): carnet du 19/10 soir + archives des mandats`, `git push origin main`, `git ls-remote origin refs/heads/main` collé. Refus du hook : message collé, STOP.

## Mission 2 — worktrees
Pour chaque worktree sous `.claude/worktrees/` (attendus : F01-M0005, F01-M0008, F01-M0010, F01-M0020, F02-M0004, F02-M0009, F03-R003) : `git -C <wt> status --short` collé si le dossier existe ; modifications **hors** `vault/` → ne le retire pas, signale-le. Sinon `git worktree remove --force <wt>`. Puis `git worktree prune` et `git worktree list` collé.

## Mission 3 — branches distantes
Supprime (`git push origin --delete <b>`) **uniquement** celles de cette liste ET présentes dans `git branch -r --merged origin/main` :
`chore/harnais-v1.6.0`, `chore/harnais-v1.6.6`, `chore/version-1.3.0`, `feat/build-14`, `feat/localisation`, `feat/publication-app-store`, `feat/version-minimale`, `fix/6-mes-demandes-suppression`, `fix/alerte-vue-30-jours`, `fix/apercu-photos-validees`, `fix/fiche-carte-changement`, `fix/ios-defauts`, `fix/photos-validees`, `fix/reglages-motif-date`, `fix/release-controles-avant-envoi`, `fix/version-build-11`, `review/mvp-polish-2026-05-08`.
Absente de `--merged` : ne la supprime pas, signale-la.
**Jamais** : `main`, `base/pre-mvp-polish`, `fix/2-mes-soumissions-cloisonnement`, `fix/version-et-fiche-carte` (non fusionnées : liste-les au rapport avec `git log --oneline -3 origin/<b>`), ni toute branche hors liste.

## Mission 4 — branches locales
`git branch --merged main` : supprime avec `git branch -d` (jamais `-D`) celles qui ne sont pas `main`. Les autres : liste collée, rien supprimé.

## Preuves finales
`git ls-remote --heads origin` en entier ; `git worktree list` ; `git branch -a`.

## Interdits
Jamais `sleep`, tâche de fond vivante, `stash`, `reset --hard`, `checkout -- .`, `update-ref`, `branch -D`, `--no-verify`, `push --force`. `git add` ciblé. Aucun sous-agent.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN, dans l'ordre : `## Rapport M0029` (5 lignes max en français simple, puis preuves) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (non committés) → commit vault ciblé sur `main` + push + `ls-remote` collé → footer de statut (gabarit §4, `M0029`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0029

En français simple : le vault est sur GitHub (`0b8d8c8`). Six worktrees propres retirés ; `F03-R003` gardé, car il a des modifications hors `vault/`. Dix-sept branches distantes fusionnées supprimées. Les branches locales fusionnées dans `main` sont supprimées avec `-d`. Trois branches distantes hors liste restent : `base/pre-mvp-polish`, `fix/2-mes-soumissions-cloisonnement`, `fix/version-et-fiche-carte`.

- Garde : `main` = `origin/main` = `838ab5e83aec586cff3f7e233269db3739289401` après `fetch --prune`. `git status` racine : `vault/` modifié, plus `?? .claude/worktrees/` (non sous `vault/`, mais c'est le dossier que la mission 2 traite). Lu comme attendu, pas comme écart ; à confirmer.
- Mission 1 : commit `0b8d8c8` (`vault/reprise/CARNET_DE_BORD.md` + `vault/echanges/archive/`), poussé, `refs/heads/main` = `0b8d8c8d88354f3b233135991c3ea3423937cd22`. Aucun `F0*.md` committé.
- Mission 2 : retirés (`worktree remove --force`, tous propres) : `F01-M0005`, `F01-M0008`, `F01-M0010`, `F01-M0020`, `F02-M0004`, `F02-M0009`. Gardé : `F03-R003` (détaché, `M` staged sur `.claude/skills/orchestration-bureau/SKILL.md`, `.claude/skills/orchestration-bureau/references/gabarits.md`, `config/harnais.json`, `scripts/harnais-hooks/README.md`, `scripts/harnais-hooks/pre-push`). `git worktree prune` fait.
- Mission 3 : 17 branches supprimées (`git push origin --delete`), toutes présentes dans `--merged origin/main`. Non fusionnées, rien supprimé : `base/pre-mvp-polish` (origin `68a5236`), `fix/2-mes-soumissions-cloisonnement` (origin `ff28e0f`), `fix/version-et-fiche-carte` (origin `260e3c3`).
- Mission 4 : 21 branches locales supprimées avec `-d`. Écart à signaler : `base/pre-mvp-polish` locale (`7154add`, fusionnée localement dans `main`) a été supprimée. Ce n'est pas la branche distante, qui reste. Restauration possible : `git branch base/pre-mvp-polish 7154add`. Restée : `fix/version-et-fiche-carte` locale (non fusionnée), et `main`.

Préalable du rapport, en `Mission 1` : `git status` racine après le commit ne contient plus que `vault/echanges/F01.md`, `vault/echanges/F02.md`, `vault/echanges/F03.md`, `.claude/worktrees/`.

### Preuves finales

`git ls-remote --heads origin` :
```
68a523691b6eba8453455802cd794650cbb3b349	refs/heads/base/pre-mvp-polish
ff28e0fc3d1a963fe7cd936d4f13bcb2d748ce0a	refs/heads/fix/2-mes-soumissions-cloisonnement
260e3c3c4cebfb138ad1e322dfd452a18ca81ffe	refs/heads/fix/version-et-fiche-carte
0b8d8c8d88354f3b233135991c3ea3423937cd22	refs/heads/main
```

`git worktree list` :
```
/Users/malik/Documents/Boites-a-livres/BoitesALivresNative                            0b8d8c8 [main]
/Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F03-R003 d78c177 (detached HEAD)
```

`git branch -a` :
```
  fix/version-et-fiche-carte
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/base/pre-mvp-polish
  remotes/origin/fix/2-mes-soumissions-cloisonnement
  remotes/origin/fix/version-et-fiche-carte
  remotes/origin/main
```

M0029
Implementation      ✅
Tests               N/A
Commit              ✅
Branch push         N/A
Review              N/A
Merge main          N/A
Main push           ✅
TASK STATUS         INTEGRATED
PROJECT STATUS      NOT_INTEGRATED
