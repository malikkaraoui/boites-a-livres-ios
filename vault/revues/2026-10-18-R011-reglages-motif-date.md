---
verdict: GO
tip: a05ca6525af5065266c009f65616fb0b8c98a096
niveau: N1
---

# R011 -- relecture N1 : motif de refus et date relative (Mes soumissions)

## Périmètre relu

`git diff a9e33d8 a05ca65` : `App/SettingsView.swift`, `en.lproj/Localizable.strings`, `fr.lproj/Localizable.strings`, `CHANGELOG.md`. SettingsViewModel.swift et Services/SupabaseService.swift ne sont pas touchés (vérifié au `--stat`).

## Défauts trouvés

Aucun TEST ROUGE.

- REMARQUE `App/SettingsView.swift:552` : `relativeDate` renvoie désormais « — » en dur (non localisé) au lieu de la chaîne brute. Ce changement touche aussi les lignes 305, 326 et 393 (boîtes, avis, demandes), pas seulement « Mes soumissions ». Améliorations attendues, mais le tiret devrait passer par `NSLocalizedString` ou rester documenté.
- REMARQUE `App/SettingsView.swift:341` : `if let note, !note.isEmpty` ne couvre pas un motif faits uniquement d'espaces. Il afficherait « Motif :   ». Un `trimmingCharacters(in: .whitespacesAndNewlines)` lèverait le doute. Le cahier des charges dit « vide ou nil », donc ce n'est pas une régression prouvée.
- REMARQUE : aucun test versionné du parseur de dates dans le dépôt ; le harnais de l'auteur est hors dépôt. À porter en XCTest si une cible de test existe.

## Vérifications exécutées

- Lecture de `normalizeFraction` (SettingsView.swift:23-30) et de `rowBody` (337-346) : logique correcte pour note nil et note vide.
- Clés de localisation : `"Motif : %@"` présente une seule fois dans fr et en, format `%@` identique au code, espace ASCII vérifiée (aucun NBSP, `od -c`).
- `review_notes` est bien `String?` (Services/SupabaseService.swift:330), compatible avec `note: String?`.
- Test hors dépôt (scratchpad, `swiftc` Swift 6.4) de `ISODateParser` sur 13 entrées : 6 décimales, 3, 2 et 1 décimale, 9 décimales (tronquée à 3), sans fraction, `Z`, offset `+02:00` et `-05:30`, `.Z` sans chiffre, chaîne vide, chaîne invalide. Toutes les sorties sont correctes (ex. `.3Z` -> `.300Z` -> 1792245815.300 ; `""` et texte invalide -> nil).

## Verdict

Verdict : GO
