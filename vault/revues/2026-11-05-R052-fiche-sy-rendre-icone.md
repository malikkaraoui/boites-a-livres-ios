---
date: 2026-11-05
tags: [revue, fiche, itineraire, carte, icone, build-31]
mandat: M0062
revue: R052
branche: feat/fiche-sy-rendre-icone
base: 63c081854ce13d2bbe3fcf9890e1306a87ad4060
tip: 484abc9aab64cc10a32db4677a50dbdea2b5613e
niveau: N3
verdict: GO
---

# R052 — Fiche : « S'y rendre » + « Voir sur la carte » ; icône par défaut ; build 31

Relecture indépendante (sous-agent frais, lecture seule) de `origin/main..484abc9`.

## Points vérifiés

| # | Point | Statut | Preuve |
|---|---|---|---|
| 1 | Deux boutons à la place de « Ouvrir dans Plans » | OK | `Views/Detail/DetailView.swift:40`, `directionsButtons` l.368-391 |
| 2 | « S'y rendre » via MapKit, mode à pied, sans `maps://` | OK | `DetailView.swift:658-663` (`MKPlacemark`, `MKMapItem.openInMaps`, `MKLaunchOptionsDirectionsModeWalking`) |
| 3 | « Voir sur la carte » ne rouvre pas la fiche | OK | `DetailView.swift:665-669` pose seulement `pendingMapFocus` ; `App/ContentView.swift:60-66` vide `mapPath` et `listPath` ; `App/MapScreen.swift:213-222` centre la caméra (700 m) sans écrire `vm.selectedBox` |
| 4 | `pendingBoxId` inchangé | OK | Aucune ligne du diff ; usages `AppDelegate.swift:48,59`, `ContentView.swift:57`, `MapScreen.swift:208-211` |
| 5 | Icône par défaut = `0d414f5` octet pour octet ; Halloween archivée hors cible | OK | `git diff --quiet 0d414f5 484abc9` sur le PNG et `Contents.json` : vide ; archive `docs/icones/archive/halloween-2026/` absente de `project.pbxproj` / `project.yml` |
| 6 | Version 31 cohérente | OK | `project.pbxproj:425,508` ; `project.yml:25` ; `CHANGELOG.md:14` ; `release-notes/*.txt` ligne 1 ; `MARKETING_VERSION` 1.3.0 inchangé |
| 7 | `Localizable.xcstrings` | OK | JSON valide ; « S'y rendre » et « Voir sur la carte » en fr et en ; « Ouvrir dans Plans » supprimée |
| 8 | Périmètre | OK | 13 fichiers dans `63c0818..484abc9`, aucun des fichiers interdits ; aucun payload, endpoint ni base modifié |
| 9 | Compilation (statique) | OK | Imports MapKit présents ; `MapFocus` `Equatable` ; `BookBox.coordinate` existe. Build Release réel passé (voir ci-dessous) |
| 10 | Budget | OK | `controle-instructions` : 4 OK, 0 ATTENTION, 0 BLOQUE ; `EXIT=0` |

## Réserves

- **R1 (mineure, non bloquante)** : `App/MapScreen.swift:13` (`focusedBoxId`) n'est remis à `nil` que sur tap du fond de carte et sur `selectBox`. Si la feuille est fermée par glissement, le pin reste en surbrillance. Non corrigé : pas de test rouge, c'est une remarque.

## Non vérifié à l'exécution

- Le comportement réel des deux `onChange` déclenchés par `pendingMapFocus` (`ContentView.swift:60` et `MapScreen.swift:213`) et le centrage de la caméra : relecture statique seulement. À confirmer sur simulateur ou appareil, depuis la Liste et depuis la Carte.

## Tests sur le résultat de fusion (scratch, `origin/main` + `--no-ff 484abc9`)

- `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` : `BUILD SUCCEEDED`, `BUILD_EXIT=0`.
- `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail, `TEST_EXIT=0`.
