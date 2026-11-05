---
verdict: GO
tip: cd323c0a496501ee055171e4161bec386fdce538
niveau: N3
mandat: M0064
branche: feat/apercu-fiche-ios
base: a3ec9c62da2eb0ec51c498d1c9eb63a9e413f2b1
---

# R053b — Aperçu touchable, photo 180 pt, appareil photo, pastille ; copie par appui long (M0064, #71)

Doublage N3 indépendant (sous-agent frais, lecture seule) du tip `cd323c0` (passage R053b après le correctif de R053 à `c5d7408`).

## Constats du R053 (RESERVE) et suites
- Bloquant : détent sélectionné `.height(320)` absent des détents présentés → corrigé (`App/MapScreen.swift:10`, `:275` = 360). Résolu.
- Mineur : `coordLongPressFired` remis à false par timer après 0,6 s → corrigé (remise à false dans l'action du bouton). Résolu.
- Mineur résiduel (non bloquant) : relâchement hors du bouton de format → flag pouvant ignorer un tap. Ouvert en issue #72.
- Info : appareil photo aussi affiché si `photo_url` échoue sans photo validée (voulu, aucune photo publiée ni validée) ; appui long sur le bouton copie peut copier deux fois (sans effet). Non bloquants.

## Règles 1-6
1. Aperçu touchable partout : OK (`Views/Components/BookBoxSheet.swift` contentShape + onTapGesture → onDetail ; bouton « Voir le détail » inchangé).
2. Photo 180 pt, feuille 360 pt : OK (`BookBoxSheet.swift` photoHeight ; `App/MapScreen.swift:10`, `:182`, `:275`).
3. Appareil photo seulement sans photo, liste chargée : OK (`BookBoxSheet.swift` branche `listLoaded`).
4. Pastille ConditionBadge seulement si valeur valide : OK (`BookBoxSheet.swift`).
5. Appui long sur toute la cellule coordonnées : OK (`Views/Detail/DetailView.swift` simultaneousGesture, surlignage, haptique, copie) ; toucher simple inchangé.
6. Fichiers interdits intacts ; version 32 cohérente (project.yml, project.pbxproj ×2, CHANGELOG « Build 32 », release-notes fr/en).

## Preuves exécutées
- Build Release iOS générique : `BUILD SUCCEEDED` (après correctif).
- `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail.
- Contrôle budget sur `cd323c0` : `controle-instructions ... 4 OK, 0 ATTENTION, 0 BLOQUE`.

## Non vérifié à l'écran
- Aucune capture d'écran utile : le simulateur démarre et l'app s'installe, mais la capture reste sur l'écran de lancement. Axe UX : ⚠️ non vérifié à l'écran.
- Glisser de feuille vs tap, appui long de 0,5 s, haptiques, surlignage, rendu de la pastille et de l'appareil photo, hauteur 360 pt, chaînes FR/EN : à vérifier sur iPhone.
