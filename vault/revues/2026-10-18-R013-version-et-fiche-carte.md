---
verdict: RESERVE
tip: 260e3c3c4cebfb138ad1e322dfd452a18ca81ffe
niveau: N3
---

# R013 — Doublage N3 de M0017 (version dans Réglages + fiche sur la carte)

Revue en lecture seule du worktree détaché `.claude/worktrees/R013-M0017` :
`git rev-parse HEAD` = `260e3c3c4cebfb138ad1e322dfd452a18ca81ffe`. Base `origin/main` = `02868ab`.
Diff relu en entier : `project.pbxproj`, `App/MapScreen.swift`, `App/SettingsView.swift`, `CHANGELOG.md`, `project.yml`.

## Verdict : RESERVE

Le volet (A), la version, est correct. Le volet (B), la fiche, est sans effet sur le cas observé
sur le terrain. C'est prouvé par le code et les captures (voir D1) : le symptôme reste en place.

## (A) Version : vérifiée

- `App/SettingsView.swift:511-514` : `versionLabel` renvoie `"v\(version) (\(build))"`, avec `build` lu
  dans `CFBundleVersion`.
- `Info.plist:17-20` : `CFBundleShortVersionString = $(MARKETING_VERSION)`,
  `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`.
- `project.yml:24-25` : `MARKETING_VERSION: 1.3.0`, `CURRENT_PROJECT_VERSION: 11`.
- `project.pbxproj:337` et `:420` : `CURRENT_PROJECT_VERSION = 11` (Debug et Release),
  `:346` et `:429` : `MARKETING_VERSION = 1.3.0`. Aucune autre occurrence.
- Affichage attendu : « v1.3.0 (11) ». Ce n'est pas vu à l'écran (voir la checklist).
- `App/ContentView.swift` n'apparaît pas dans le diff (`git diff --stat origin/main..HEAD -- App/ContentView.swift`
  est vide). La ligne 58 lit toujours `CFBundleShortVersionString`, sans changement.

## (B) Fiche sur la carte : ce que dit le code

### Le correctif est cohérent en soi
- `MapScreen.swift:21` : `static let sheetSmallDetent = .height(320)`.
- Affectations de `sheetDetent` : `:10` (init `.height(320)`), `:199` (`small`, soit 320), `:252` et `:256`
  (`initial`, soit 320). Une seule autre valeur est possible : `trigger`, posée par le système quand on glisse.
  Aucun chemin n'affecte donc une valeur absente de `[small, trigger]` (`:188`).
- Glisser vers le haut : `:193-201`. Sur `onChange`, si `new == trigger`, la fiche se ferme sans animation,
  la détente revient à `small` et `path.append(id)` ouvre le détail. Ce code n'a pas changé.
- Bouton « Voir le détail » : `Views/Components/BookBoxSheet.swift:94-107` appelle `onDetail`, qui exécute
  `MapScreen.swift:183-187` (`selectedBox = nil` puis `path.append`). Ce code n'a pas changé.
- `selectBox` (`:242-259`) : même délai de 0,32 s avant de rouvrir, même structure. Seule la constante change.

### D1 (défaut prouvé) : le correctif ne change rien pour #14183 → #227
- L'icône `photo.fill` de la fiche ne s'affiche que si `box.photo_url != nil`
  (`BookBoxSheet.swift:73`, identique sur `origin/main`).
- Les captures terrain (`vault/revues/captures-M0017/terrain-video-1.png` et `-2.png`, dépôt principal)
  montrent cette icône sur la fiche **#14183** et sur la fiche **#227**. Les deux boîtes ont donc une `photo_url`.
- Sur `origin/main`, `MapScreen.swift:177` et `:244` calculaient donc déjà `.height(320)` pour ces deux boîtes,
  et `sheetDetent` valait déjà 320 partout. Le code d'avant et celui d'après sont identiques pour ce scénario.
- Conclusion : l'hypothèse de l'auteur (« détente absente de la liste » ou « hauteur 320/200 qui change »)
  ne peut pas expliquer le symptôme observé. Le symptôme se produit aussi dans l'autre sens
  (#227 → #14183, terrain-video-2, rangée du bas). Le correctif uniformise la hauteur, ce qui est
  sans risque, mais il ne corrige pas le bug signalé.
- Ce qui est prouvé : l'absence d'effet du correctif sur ce scénario.
  Ce qui ne l'est pas : la vraie cause, qui n'a été reproduite ni par l'auteur ni par le réviseur.

### Pistes de cause (non prouvées, à instrumenter)
1. Présentation pendant la fermeture. Sur les captures, la carte apparaît sans fiche, puis la nouvelle fiche
   s'ouvre en grand. Il faut vérifier si 0,32 s (`:251`) suffit pour que la fermeture soit vraiment finie,
   ou si SwiftUI présente la nouvelle feuille avant `presentationDetents`/`selection`.
2. Ordre des gestes. Le `simultaneousGesture` de la carte (`:62-70`) peut se déclencher **avant** le
   `onTapGesture` de l'annotation (`:52`), alors que `isHandlingAnnotationTap` vaut encore `false`.
   Dans ce cas, `selectedBox = nil`, puis `selectBox` passe par la branche `else` (`:255-258`) et
   présente la nouvelle fiche **immédiatement**, en pleine fermeture, sans le délai de 0,32 s.
   C'est plausible avec le symptôme « grand, flou, puis se replace ». Non prouvé.
3. Il faut instrumenter (log horodaté de `selectBox`, du tap carte et de `sheetDetent`) ou reproduire sur
   simulateur avec deux boîtes **à photo** avant de proposer un nouveau correctif.

## Builds (rejoués par le réviseur, sans xcpretty)

```
Release, generic/platform=iOS, CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
lignes "error:" : 0   (3 lignes "warning:")

Debug, platform=iOS Simulator,name=iPhone 17, ONLY_ACTIVE_ARCH=YES, CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
lignes "error:" : 0
```

Tests : le projet n'a **aucune cible de test** (`project.yml:39`, `testTargets: []`). Aucun test n'a été exécuté.

## Checklist fondateur (iPhone, build 1.3.0 (11))

- [ ] Réglages : la version affichée est « v1.3.0 (11) ».
- [ ] Carte : toucher #14183, puis #227, puis faire l'inverse. La nouvelle fiche doit apparaître à 320 pt,
      jamais presque plein écran ni floue. **D1 prévoit que le symptôme reste**, il faut le confirmer.
- [ ] Même test entre une boîte avec photo et une boîte sans photo (pastille atténuée).
- [ ] Toucher un point, puis toucher vite un autre point avant la fin de la fermeture.
- [ ] Glisser une fiche vers le haut : le détail s'ouvre, et au retour la fiche n'est pas restée en grand.
- [ ] Bouton « Voir le détail » : le détail de la bonne boîte s'ouvre.
- [ ] Toucher la carte hors d'un point : la fiche se ferme.

## Issues suggérées (hors réserve)

1. Course dans `selectBox` : toucher B puis C en moins de 0,32 s. La branche `else` présente C, puis le
   `asyncAfter` en attente remplace C par B (`MapScreen.swift:249-258`). Le défaut est antérieur au correctif.
2. Remplacer le délai fixe de 0,32 s par une présentation pilotée par la fin de fermeture
   (`onDismiss` de `.sheet`), ou garder la feuille ouverte et changer seulement son contenu.
3. Ajouter une cible de test (au minimum des tests unitaires), car le projet n'en a aucune.
4. `MapScreen.swift:10` répète `.height(320)` au lieu d'utiliser `Self.sheetSmallDetent`.
