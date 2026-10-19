---
date: 2026-10-19
tags: [revue, release, preflight, issue-33]
verdict: BLOQUE
tip: 0c9f78c6bb59812577d4933b67b2d0787d01a2ba
niveau: N3
---

# R025 -- Préflight App Store Connect (M0028, branche `fix/release-controles-avant-envoi`)

Doublage N3 par relecteur frais, lecture seule. Premier passage sur le tip `0c9f78c`.

## Réserve prouvée (BLOQUE)

`publish()` n'avait plus de déclaration `app` après le retrait de `findApp` au profit du préflight.
L'étape `traitement` (`waitForBuild(client, app.id, …)`) échouait donc avec `app is not defined`,
après les deux appels `xcodebuild` (archive et exportArchive). Reproduit par le relecteur dans une copie
hors dépôt avec un préflight valide : sortie `arrêt à l'étape « traitement » : app is not defined`.

Aucun test ne couvrait ce chemin : tous les tests de `publish` s'arrêtaient avant l'étape `traitement`.

Correction demandée : rétablir `app` depuis le retour de `preflight`, et ajouter un test du chemin complet.

## Points vérifiés

- Ordre : `assertConfirmed` puis `preflight` avant tout `runXcodeFn` ; le préflight ne fait que des GET.
- Pagination de `listVersions` complète, bornée, avec erreur au-delà de la borne.
- Garde OK-APPLE inchangée. Aucun secret, aucune dépendance ajoutée.

## Suite

Correctif sur le même branche (commit `8833713`), puis doublage R026.
