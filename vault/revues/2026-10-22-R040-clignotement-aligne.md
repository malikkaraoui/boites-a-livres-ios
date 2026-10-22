---
date: 2026-10-22
tags: [revue, clignotement, alignement, build-25]
revue: R040
mandat: M0048
verdict: GO
tip: a52d9496cc17537216c1dcac169f7291e48bba04
base: d2fc9eb86f690f8d9044e52e6d048be8242b0c52
niveau: N3
---

# R040 — Cadre clignotant aligné sur l'élément (M0048, build 25)

## Verdict

**GO**, sans réserve prouvée par un test rouge. Trois remarques non bloquantes, sans défaut démontré.

## Appels de `missingHighlight` (10)

Le rayon par défaut est 12. « Forme » = forme visible de l'élément.

| fichier:ligne | avant | après | rayon utilisé / rayon de la forme |
|---|---|---|---|
| App/AddBoxView.swift:225 (inchangé) | aligné : après `.padding(16).background().clipShape(14)` | aligné | 14 / 14 |
| App/AddBoxView.swift:290 (déplacé) | non : englobait `.padding(.horizontal,16)` | aligné : encadre le texte seul | 8 / aucune forme (Text sans fond) |
| Views/Components/DeletionRequestSheet.swift:66 (déplacé) | non : englobait `.padding(.horizontal,20)` | aligné : ZStack = carte du TextEditor | 12 / 12 |
| Views/Components/ReviewSubmitSheet.swift:150 (déplacé) | non : marges 20 H + 14 B dans `proximityRow`, la carte visible rétrécissait | aligné : carte `proximityRow` exacte | 12 / 12 |
| Views/Components/ReviewSubmitSheet.swift:319 (inchangé) | aligné : `ConditionPicker`, sans marge | aligné | 12 / 12 |
| Views/Components/ReviewSubmitSheet.swift:400 (inchangé) | aligné : ZStack du TextEditor | aligné | 12 / 12 |
| Views/Components/LocationUpdateSheet.swift:124 (inchangé) | aligné : notice en texte nu | aligné | 8 / aucune forme |
| Views/Components/LocationUpdateSheet.swift:135 (inchangé) | idem | idem | 8 / aucune forme |
| Views/Components/LocationUpdateSheet.swift:249 (inchangé) | idem | idem | 8 / aucune forme |

Le cadre enveloppe désormais la forme visible dans tous les cas qui avaient une forme. Le rayon 8 de la ligne 290 et des trois de LocationUpdateSheet n'a pas de référent : ce n'est pas une non-conformité.

## Autres contrôles

- **`.id(...)`** : aucun identifiant modifié (`proximity`, `submit`, `reason`). `proximity` ne couvre plus les 14 pt de marge basse : décalage de quelques points de l'ancre de défilement, sans effet fonctionnel.
- **Périmètre du diff** : 8 fichiers (AddBoxView, DeletionRequestSheet, ReviewSubmitSheet, CHANGELOG.md, project.yml, project.pbxproj, release-notes en-US et fr-FR). Dans le Swift, seuls les modificateurs de mise en forme bougent. Aucun changement d'envoi, de payload, d'endpoint, de texte utilisateur, de base ni de migration.
- **Version 25** : `project.yml:25`, `project.pbxproj` (aucun 24 restant), `CHANGELOG.md` « Build 25 », release-notes « build 25 ».
- **Budget** (`sh "$(git config core.hooksPath)/pre-commit" --controle a52d949… --base d2fc9eb…`, hooksPath = `scripts/harnais-hooks`) : 4 OK, 0 ATTENTION, 0 BLOQUE, EXIT=0.

## Remarques non bloquantes

- Le fond orange (opacité 0.14) est peint sous le contenu. Où le contenu a un fond opaque (AddBoxView:225, ReviewSubmitSheet:400, et désormais DeletionRequestSheet:66), seul le contour 2 pt pulse. Vérifié par lecture de la superposition, non rendu.
- Le sous-titre « message de distance » du CHANGELOG ne correspond qu'à ReviewSubmitSheet:150, cohérent.

## Non vérifié par le relecteur

- Compilation complète : non relancée (interdit au relecteur ; l'auteur a fait `BUILD SUCCEEDED` sur `a52d949`). Parse seul (`swiftc -parse`) : exit 0 sur les 3 fichiers Swift.
- Rendu réel (couleurs, pulsation, alignement au pixel) : pas de capture.
- Tests : non relancés.
