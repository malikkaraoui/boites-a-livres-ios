---
verdict: GO
tip: fc50cb32d866c21e2ad3c3cc61c59d5db5df7f1c
niveau: N3
---

# R037 : bouton d'envoi grisé touchable, clignotement de ce qui manque (M0045, #51, base da9f8db)

Relecture indépendante, lecture seule. Sous-agent frais (Haiku), worktree détaché `R037-revue` sur le tip `fc50cb3`. Relecture statique : `xcodebuild` n'a pas été relancé par le relecteur (le build Release a été passé par l'auteur, voir le rapport M0045). Le sous-agent partage le modèle de l'auteur : indépendance faible, à compenser par le test sur iPhone.

## Périmètre

Cinq formulaires d'envoi traités : avis (`ReviewSubmitSheet`), demande de suppression (`DeletionRequestSheet`), ajout de boîte étape 2 (`AddBoxView`, `AddBoxViewModel`), localisation (`LocationUpdateSheet`). Logique pure : `SubmitRequirements` dans `Models/BookBox.swift`. Retour visuel commun : `Views/Components/ButtonStyles.swift`.

## Constats

- **Toucher reçu, rien envoyé** : plus de `.disabled` sur les boutons d'envoi. Chaque `submitTapped` n'appelle `submit()` que si la liste des manques est vide.
- **Ancres** : chaque ancre renvoyée par `SubmitRequirements` existe dans le `ScrollView` et porte le `missingHighlight` de la même cible.
- **Source unique** : `canSubmit` dérive de la liste ; `AddBoxViewModel.presenceOK` a été retiré.
- **Réduire les animations** : surlignage fixe 1 s, sinon 3 pulsations (≈ 1 s).
- **Payload** : aucun fichier `Services/` modifié ; les quatre appels d'envoi sont intacts.
- **Version 22** : `project.yml`, `project.pbxproj`, `Info.plist` (via `$(CURRENT_PROJECT_VERSION)`), release notes FR/EN, `CHANGELOG.md`. Cohérent.
- **Recensement `.disabled(`** : les seuls restants sont des boutons d'ouverture (`DetailView`, `ListView`, `SettingsView`) ou l'étape « Confirmer la position » ; aucun vrai bouton d'envoi oublié.

## Réserve (prouvée par lecture, pas par test)

**Phase `.failed` de `LocationUpdateSheet`** : `canSubmit` vaut faux, mais `missingRequirements` est vide. Toucher le bouton appelle `submit()`, qui sort à `guard canSubmit` sans rien montrer. Pas d'envoi, mais pas de retour non plus. Cette phase existait déjà avant M0045 (bouton alors désactivé, sans message). Le mandat ne classe en blocage que les réserves prouvées par un test rouge : celle-ci est donc une **remarque**, ouverte en issue.

## Remarques (issues)

- Dead-end de la phase `.failed` (localisation) : une fois une erreur d'envoi affichée, le bouton reste inactif sans relance possible. Pré-existant.
- Message doublé : « Ajoute une photo de la boîte » s'affiche deux fois pendant 3 s (sous la photo et sous le bouton).
- Deux toucher rapides lancent deux `pulse()` sans annulation : clignotement possiblement saccadé.
- Défilement `withAnimation` non conditionné par « Réduire les animations ».
- VoiceOver annonce actifs des boutons visuellement grisés.
- Compatibilité Swift 6 de `MissingFeedback<…>` (`@MainActor @Observable` générique) : à vérifier au build Swift 6.

## Verdict

GO. Aucune réserve prouvée par test rouge. Remarques ouvertes en issue, sans nouveau tour de correction.
