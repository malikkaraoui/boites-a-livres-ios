---
date: 2026-10-18
tags: [lecon, swiftui, sheet, preuve-ecran, M0019]
mandat: M0019
revue: R015
candidate_transverse: oui
---

# Une feuille SwiftUI qui change d'identité dans une seule mise à jour est re-présentée en `.large`

## Constat
- `.sheet(item: $x)` : si `x` passe de A à B dans **une même** mise à jour (sans `nil` committé
  entre les deux), SwiftUI ferme et re-présente la feuille ; la nouvelle `UISheetPresentationController`
  part avec la détente par défaut `com.apple.UIKit.large`, sans les `presentationDetents` demandées.
  Mesure : `detents=[com.apple.UIKit.large]`, 812 pt au lieu de `[320, 0.75]`, 354 pt.
- Sur une `Map` SwiftUI, le `simultaneousGesture(TapGesture)` de la carte s'exécute **avant** le
  `onTapGesture` d'une `Annotation`. Une garde « toucher d'annotation en cours » posée par l'annotation
  arrive donc trop tard.
- Remède retenu : feuille d'identité fixe (élément `Identifiable` à `id` constant), contenu changé sur
  place, `.id(box.id)` sur le contenu pour remettre son état à zéro.

## Méthode qui a marché (après un premier patch à l'aveugle, M0017)
- Reproduire sur simulateur avec de **vrais** touchers (XCUITest dans un projet xcodegen du scratchpad,
  identifiants d'accessibilité temporaires sur les points), captures en rafale `XCUIScreen`.
- Sonde UIKit temporaire (`UIViewRepresentable` qui remonte au `sheetPresentationController`) :
  elle lit l'état réel (détentes, hauteur), là où le code SwiftUI ne dit que l'intention.
- Contre-épreuve à une seule variable (effacement par la carte neutralisé) pour prouver la causalité.

## Pièges d'environnement
- Pas d'app Simulator graphique sur cette machine : les touchers passent par XCUITest.
- `simctl io recordVideo` peut ne pas s'arrêter sur `SIGINT` et bloquer le script : préférer les rafales
  de captures, ou borner l'arrêt.
- Créer un simulateur dédié au mandat évite de gêner une autre fenêtre qui capture en parallèle.
