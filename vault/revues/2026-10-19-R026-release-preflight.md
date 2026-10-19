---
date: 2026-10-19
tags: [revue, release, preflight, issue-33]
verdict: GO
tip: 883371330521ca1581d4c30781d94d1a9a64f959
niveau: N3
---

# R026 -- Préflight App Store Connect (M0028, branche `fix/release-controles-avant-envoi`)

Doublage N3 par relecteur frais, lecture seule, sur le tip `8833713` (correctif de R025).

## Vérifié

- Ordre : `assertConfirmed` puis `preflight` avant tout `runXcodeFn` ; aucun POST/PATCH avant le préflight.
- Variables de `publish` toutes définies (`app`, `plan`, `local`, `notes` viennent de `preflight`).
- Pagination de `listVersions` complète, bornée (erreur au-delà de 20 pages).
- Garde OK-APPLE inchangée et toujours première instruction de `publish`.
- Aucun secret affiché ou committé ; aucune dépendance ajoutée.
- `node --test scripts/release/asc.test.mjs` : 17 tests, 17 pass, 0 fail.
- Mutations : retrait de `WAITING_FOR_REVIEW`, `runXcodeFn` avant préflight, contrôle des numéros
  neutralisé, contrôle des notes neutralisé, pagination tronquée sans erreur : détectées.

## Résiduels (issues, non bloquants)

- Non détecté, trou de test : notes absentes du disque (`fr-FR.txt` manquant) ; pas de cas de test.
- Non détecté, trou de test : borne de pagination décalée d'un cran (`page > maxPages`).
- Deux mutations de garde « en attente » bloquent au lieu d'échouer : `waitForBuild` réel avec sondage
  de 30 s. Injecter `sleepFn` ou un `waitForBuild` factice réglerait le cas.
- `links.next` est suivi avec le jeton Bearer sans contrôle d'origine (issue #33, remarque 2, non traitée).
- `maxBuild` ne lit que les 20 derniers builds reçus.
- `EN_ATTENTE` : la liste des états vient du mandat ; l'énumération complète d'Apple n'a pas pu être
  vérifiée en ligne dans cette session.
