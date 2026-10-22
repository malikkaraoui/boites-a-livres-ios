---
verdict: GO
tip: a9e4be71fccc46bf1708252b9c30eed45ae029ce
niveau: N3
---

# R031 — Carte localisation (M0036, issue #34)

Relecteur : sous-agent frais (Haiku 5.5, medium), worktree détaché lecture seule sur le tip. Base : `origin/main` (739cbf6).

## Verdict : GO

Aucune réserve prouvée par le code. Les 8 décisions du fondateur sont vérifiées point par point (fichiers:lignes dans le rapport du relecteur, repris ci-dessous).

| # | Décision | Verdict |
|---|---|---|
| 1 | Écran unique, carte centrée sur la boîte, point bleu, un bouton | OK (`LocationUpdateSheet.swift`, `centerOnBox()`, `UserAnnotation()`) |
| 1b | Repère non déplacé = confirm (gps, ≤ 10 m, présence) | OK |
| 1c | Repère déplacé = move (source, ≤ 50 m, présence) | OK |
| 2 | Aucun changement de payload ni d'endpoint | OK (`submit()` identique, seule la garde change) |
| 3 | `moveMaxMeters` = 100, bouton grisé + texte | OK |
| 4 | Présence 50 m, alerte 100 m, plus de `proximityMeters` | OK (grep vide sur le dépôt) |
| 5 | Alerte activée par défaut, aucune demande au lancement | OK (`alertEnabled(stored:) = stored ?? true` ; `requestAlwaysAuthorization` seulement dans `enable()`, sur action utilisateur) |
| 6 | Textes « 100 m » | OK |
| 7 | Build 17, MARKETING 1.3.0, CHANGELOG « Build 17 » | OK |
| 8 | Code mort, optionnels, compilation (lecture) | OK à la lecture |

## Remarques (non bloquantes, converties en issues)

- **A** : seuil de 1 m pour `pinMoved` ; effleurement possible qui bascule en « déplacé ». Issue #37 (à vérifier sur iPhone).
- **B** : adresse possiblement périmée si l'envoi précède le géocodage inverse. Pré-existant. Issue #35.
- **C** : `ProximityReminder` affiche « alerte désactivée » aux utilisateurs sans « Toujours », conséquence du défaut activé. Décision produit. Issue #36.
- **D** : les paragraphes de remerciement des notes (dont la mention d'une faille de sécurité signalée par une personne nommée) viennent de la base `docs/notes-1.3.0`, pas de M0036. Hors périmètre de ce mandat : à valider par le fondateur avant publication.
- **E** : fixtures `asc.test.mjs` à 16 : sans effet.

## Non vérifié par ce relecteur

- Compilation (lecture seule, pas de `xcodebuild`). Compilation vérifiée ensuite par l'auteur : `BUILD SUCCEEDED` (Release, generic iOS).
- Comportement MapKit réel (seuil 1 m, ordre des `onMapCameraChange`), présence de « Toujours » : appareil requis.

## Budget

`pre-commit --controle a9e4be71 --base 739cbf67` : 4 OK, 0 ATTENTION, 0 BLOQUE.
