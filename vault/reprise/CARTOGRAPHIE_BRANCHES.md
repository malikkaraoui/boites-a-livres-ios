---
date: 2026-10-18
tags: [cartographie, branches, worktrees]
genere_par: F03 M0019 (lecture git réelle : fetch --prune, for-each-ref, worktree list, branch -vv, merge-base --is-ancestor, rev-list --left-right --count origin/main...<branche>)
derniere_maj: 2026-10-18T21:01:32+0200
---

# Cartographie branches / worktrees vs `main`

> Régénéré par lecture git réelle, remplace intégralement la version précédente (qui n'était
> que le gabarit). Une ligne que git ne confirme pas ne figure pas ici.

`origin/main` = `1e73f95` au moment de la lecture. Colonne « vs origin/main » = behind / ahead.

## Branches actives / récentes

| Branche | Tip | vs origin/main | Statut RÉEL |
|---|---|---|---|
| `fix/fiche-carte-changement` | `b7c3fc8` | behind 2 / ahead 0 | **MERGÉE** — M0019, fiche carte + build 12, merge `a4a58b3`, R015 GO `1e73f95` |
| `fix/version-et-fiche-carte` | `260e3c3` | behind 9 / ahead 1 | **NON MERGÉE** — M0017, R013 RESERVE ; remplacée par M0018 (version) et M0019 (fiche) ; worktrees `F02-M0017`, `R013-M0017` |
| `fix/version-build-11` | `a7f0afa` | behind 8 / ahead 0 | **MERGÉE** — M0018, build 11 |
| `fix/reglages-motif-date` | `a05ca65` | behind 18 / ahead 0 | **MERGÉE** |
| `fix/apercu-photos-validees` | `7c7a735` | behind 13 / ahead 0 | **MERGÉE** |
| `fix/photos-validees` | `66123e8` | behind 27 / ahead 0 | **MERGÉE** |
| `chore/harnais-v1.6.6` | `c86a208` | behind 26 / ahead 0 | **MERGÉE** |

## Branches anciennes, sans activité récente

Toutes MERGÉES (ahead 0) : `base/pre-mvp-polish` 7154add (2026-05-07), `review/mvp-polish-2026-05-08`
2e88ff7, `chore/harnais-v1.6.0` 8a197e9, `chore/niveaux` bb366bc, `chore/version-1.3.0` 2776e48,
`fix/6-mes-demandes-suppression` bf8adbc, `fix/ios-defauts` 520caff (2026-10-15).

## Branches distantes supprimées (`gone`, locales orphelines)

`chore/harnais-suivi` ceb26fa, `chore/signature` 71f62cd — toutes deux mergées. Signalées, non supprimées.

## Worktrees

| Worktree | Branche | À retirer ? |
|---|---|---|
| `.claude/worktrees/F02-M0017` | `fix/version-et-fiche-carte` | à arbitrer (M0017 non mergé, remplacé) |
| `.claude/worktrees/R013-M0017` | détaché `260e3c3` | oui après arbitrage M0017 |
| `.claude/worktrees/F01-M0005` | `fix/ios-defauts` (mergée) | oui |
| `.claude/worktrees/F01-M0010` | `fix/photos-validees` (mergée) | oui |
| `.claude/worktrees/F02-M0004` | `chore/harnais-v1.6.0` (mergée) | oui |
| `.claude/worktrees/F02-M0009` | `chore/version-1.3.0` (mergée) | oui |
| `.claude/worktrees/F01-M0008` | détaché `111e063` | oui |
| `.claude/worktrees/F03-R003` | détaché `d78c177` | oui |
