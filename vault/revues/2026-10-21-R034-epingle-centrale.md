---
verdict: GO
tip: d426653cfd05b497766f803879e3feb2067d643a
niveau: N3
mandat: M0041
revue: R034
base: 709afe9dcad1dd59cce407f787b7ea348ac92fdc
---

# R034 — Ajout de boîte : épingle fixe au centre (M0041), build 19

Diff relu : `709afe9..d426653`. Relecteur : sous-agent frais, lecture seule sur un worktree détaché (`F01-M0041-rev`). Vérifications fichier:ligne recontrôlées par la session mère.

## Verdict : GO

Aucune réserve prouvée par un test rouge. Le code tient les 7 points du cahier des charges. Les remarques suivantes deviennent des issues, pas un nouveau tour.

## Points du cahier des charges

| # | Point | Verdict | Preuve |
|---|---|---|---|
| 1 | Épingle fixe au centre, repère = centre de la caméra | OK | `App/AddBoxView.swift:54-69` (Map + `UserAnnotation`, `onMapCameraChange(.onEnd)` → `followCamera`, overlay sans hit-testing), `ViewModels/AddBoxViewModel.swift:70-72` |
| 2 | Première ouverture centrée sur le premier fix frais, cache ignoré | OK | `ViewModels/AddBoxViewModel.swift:42-49` (init), `:55-62` (`isFresh` puis `shouldCenterOnFirstFix`, 300 m), `Models/BookBox.swift:27-29`, `:32-34` |
| 3 | « Replacer » : caméra sur le point posé, sans recentrage GPS | OK | `ViewModels/AddBoxViewModel.swift:75-79` (`waitingFreshFix = false`, caméra sur `pinCoordinate`) |
| 4 | Bandeau « Déplace la carte pour placer la boîte » | OK | `App/AddBoxView.swift:74` |
| 5 | Inchangés : note, 50 m, présence, payload, `LocationRules.source` | OK | Aucun hunk du diff sur `AddBoxView.swift:219-242` et `:309-318` ; `canSendManual` `Models/BookBox.swift:21-22` ; `source` utilisé par `Views/Components/LocationUpdateSheet.swift:320` |
| 6 | Code mort du toucher supprimé | OK | Grep dépôt : `firstFixEffect`, `FirstFixEffect`, `cameraOnly`, `placePin`, `userPlacedPin`, `MapReader` : zéro occurrence |
| 7 | Build 19 cohérent | OK | `project.yml:25`, `project.pbxproj:357` et `:440`, `CHANGELOG.md` « Build 19 », `release-notes/fr-FR.txt:1` et `en-US.txt:1` (aucune puce ajoutée) |

Rangement R033 : `vault/revues/2026-10-21-R033-premier-fix-gps.md` est à la racine ; `BoitesALivresNative/vault/` n'existe plus dans le dépôt.

## Remarques (issues, non bloquantes)

1. Pincement non détecté, commentaire faux : `ViewModels/AddBoxViewModel.swift:64` dit « glissée ou pincée », seul `DragGesture` appelle `markMovedByUser`. Un pincement avant le premier fix est écrasé par le recentrage.
2. Repère et adresse peuvent diverger pendant le géocodage : la carte reste interactive pendant `isGeocoding`. Pré-existant depuis M0039.
3. Carte sur `defaultLocation` (500 m) si aucune position n'est connue à l'init, le cache plus ancien étant ignoré. Ce n'est pas la France, mais aucune position connue ne s'affiche tant qu'aucun fix frais n'arrive.
4. Style : `positionStepOpenedAt` n'est plus réassigné et pourrait être `let`.

## Ce qui n'a pas pu être vérifié ici

- Alignement réel de l'épingle (`.offset(y: -18)`) et lisibilité sous la barre de navigation : à l'écran seulement.
- `simultaneousGesture(DragGesture)` avec l'inertie du pan sur appareil.
- Compilation : faite par la session mère (`xcodebuild` Release, `BUILD SUCCEEDED`), non refaite par le relecteur.

## Contrôle de budget

```
controle-instructions : 4 fichier(s) charge(s) d'office dans d426653cfd05b497766f803879e3feb2067d643a (base 709afe9dcad1dd59cce407f787b7ea348ac92fdc) -- 4 OK, 0 ATTENTION, 0 BLOQUE
```
