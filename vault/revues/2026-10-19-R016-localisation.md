---
date: 2026-10-19
tags: [revue, localisation, build-13]
revue: R016
mandat: M0020
niveau: N3
verdict: GO
tip: 9f9c343bcd52b349743e68a82785116f4c7b0422
---

# R016 — Localisation (build 13) : GO

Relecteur indépendant (sous-agent frais, lecture seule, worktree détaché sur le tip).

## Vérifié
- Build Release : `BUILD SUCCEEDED` (tip ; et de nouveau sur le résultat du merge `bf3838e`).
- Logique pure : 36 pass / 0 fail, sur les vrais `Models/BookBox.swift` et `Models/BoxReview.swift` (barres, envoi ≤10 m, anti-répétition 30 j, 20 régions triées, saisie des livres).
- Payload `insertLocationUpdate` : exactement les 12 colonnes accordées ; aucune `status`, `old_*`, `reviewed_at`, `review_notes`.
- Aucune position utilisateur hors position proposée pour la boîte ; aucun appel réseau dans `ProximityAlertService` ; permission « Toujours » seulement via `enable()`, depuis l'alerte des Réglages.
- #21 et #22 : cause de #22 prouvée (`ImageCacheService.swift`, `CachedAsyncImage.swift`, ancien `PhotoCarousel.swift`), correctif sans retrait permanent.

## Constats non bloquants (issues ouvertes après merge)
1. `distanceFilter = 50` pendant l'écran de précision : affinage GPS possiblement bloqué si immobile.
2. `manager.location` sans contrôle d'âge : un ancien fix peut activer l'envoi.
3. Géocodage inverse sans annulation ni contrôle d'ordre : adresse possiblement décalée du repère.
4. Régions posées seulement quand une position est connue ; dépend du cache des boîtes.
5. Rayon 50 m : détection d'entrée à confirmer sur appareil.
6. Boîte supprimée encore dans le cache → rappel possible.
7. Feuille de localisation ouverte même si `vm.box` est nil ; `pendingLocationBoxId` peut rester posé.
8. `UIBackgroundModes location` absent : choix défendable, à confirmer sur appareil (preuve Apple non tranchée).
9. `CLLocationManager()` instancié à chaque rendu des réglages.
10. Source `manual` : `accuracy_m` porte la précision GPS du téléphone.
11. Le « Oui » enregistre la position GPS réelle (≤ 10 m), à acter côté admin.
12. Pas de limitation de débit côté anonyme (hors périmètre).
13. `BookBoxSheet` garde le motif `failedUrls` (classe #22), à ouvrir en issue.

## Non vérifié
Précision GPS réelle, relance en arrière-plan, notification à froid, flux de permission, rendu de l'aperçu et du clavier : sur téléphone uniquement. Migration `location_updates` non appliquée (interdit) : lue, non exécutée.
