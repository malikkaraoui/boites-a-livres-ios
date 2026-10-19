---
verdict: GO
tip: da88ba6eb56a257ede590c27d8f6895fdb2555c8
niveau: N3
---

# R023 -- Publication App Store sans le site (M0027, branche `feat/publication-app-store`)

Doublage N3 par relecteurs frais (même modèle, lecture seule). Deux passes, dans l'ordre :

## Passe 1 (tip 3b343f9) -- BLOQUE

Réserve prouvée : `listVersions` ne lisait que 10 versions, sans pagination. Une version en ligne en
11e position faisait sauter le contrôle « version locale <= version en ligne », et `publish` continuait
vers l'archive et l'envoi. Scénario reproduit par un faux fetch.

Aucun secret trouvé (`BEGIN PRIVATE KEY`, identifiants réels, jetons : aucun match dans le diff ni dans
les fichiers suivis). Zéro dépendance ajoutée. Garde `OK-APPLE` vérifiée : refus sans action, pour
l'absence de confirmation, la mauvaise casse et une valeur proche. `check` n'émet que des GET.

## Correctif (commit da88ba6)

Pagination complète via `links.next` (limite 200, 20 pages au plus, erreur explicite au-delà de la
borne, pas de troncature silencieuse). Trois tests de régression ajoutés : 11 tests au total.

## Passe 2 (tip da88ba6) -- GO

La réserve est fermée : la version en ligne en 11e position est vue, et le refus sort de `planControls`
avant le `try` qui contient `xcodebuild`. Tests 11/11, `make release` sans confirmation refuse.

Remarques non bloquantes, consignées en issue (pas de nouveau tour, conformément au mandat) :
1. Le test `publish refuse AVANT tout xcodebuild` peut passer pour une autre raison (les dix premières
   versions de la fixture sont éditables) : il ne prouve pas seul la cause. Fixture à corriger.
2. Durcissement : vérifier que `links.next` pointe vers `API` avant de transmettre le jeton Bearer.
3. Les versions de la pagination ne sont lues que par `listVersions` ; le tri n'est pas garanti par Apple.
4. Limite `limit=200` sur `appStoreVersions` à confirmer contre la documentation App Store Connect.

## Non vérifié

Aucun appel d'écriture à Apple, aucun `xcodebuild -exportArchive`, aucun envoi : hors périmètre du
mandat. Le format réel de `links.next` et la limite `limit=200` restent à confirmer en production.
