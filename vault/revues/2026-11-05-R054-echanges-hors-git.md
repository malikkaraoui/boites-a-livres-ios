---
date: 2026-11-05
tags: [revue, gitignore, echanges]
mandat: M0065
revue: R054
verdict: GO
tip: 0764e4a83e547e19c2b83d234eccf6473e3f9cda
niveau: N1
---

# R054 — fichiers d'échange hors git (M0065, partie 2)

Relecture N1 par sous-agent frais, lecture seule. Périmètre : `.gitignore` + retrait d'index de `vault/echanges/F01.md` et `F02.md`.

- Diff : 3 fichiers seulement (`.gitignore`, F01.md, F02.md). Aucun autre changement.
- `/vault/echanges/F[0-9][0-9].md` ignore F01, F42, F99. `README.md` et `archive/` restent suivis.
- F01.md et F02.md absents de HEAD, présents sur disque (ignorés).
- Point non vérifié : si le bootstrap réinsère une ligne F99 calculée, elle est redondante et sans effet.
