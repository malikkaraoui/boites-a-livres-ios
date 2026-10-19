---
verdict: GO
tip: 44c6f3524a2d6fb9ec1861e2b2bdd55103dbc751
niveau: N3
---

# R022 -- Doublage indépendant : version minimale + suppression à 100 m (M0026, tip 44c6f35)

Suite de R021 (RÉSERVE, C2). Relecture par sous-agent frais, lecture seule, sur `origin/main...44c6f35`.

## Verdict

**GO.** Le point bloquant C2 est corrigé : le swipe « Supprimer » de la liste est gardé par la même règle que la fiche.

## Vérifié

- C2 : `App/ListView.swift:53` (`.disabled(!canReportDeletion(box))`), `:116-120` (position nil = refusé),
  `Models/BookBox.swift:186-192` (100 m, `<=`). Seuls deux usages de `DeletionRequestSheet` (ListView:110,
  DetailView:134), aucun deep link n'ouvre la feuille.
- Écran bloquant : `UIWindow.Level.alert + 1` (AppVersionGate.swift:43), scène active, retrait propre (:47-49),
  `.overlay` retiré de `App/BoitesALivresApp.swift`.
- Lecture en échec : le `catch` ne touche jamais `mustUpdate`. Comparaison numérique correcte.
- Fiche : seuil `<= 100`, position inconnue grisée, texte exact. Photo inchangée à 100 m.
- Aucune écriture en base (GET seul).

## Constats LOW (non bloquants)

- L1 : la garde de distance s'applique à l'ouverture de la feuille, pas à la soumission.
- L2 : `LocationService` peut initialiser `currentLocation` avec une position cachée sans contrôle d'âge.
- L3 : le texte dit « moins de 100 m », la règle est `<= 100`.

## Non testé

- Rendu et désactivation effective du bouton dans le swipe `List`.
- Affichage de `ForceUpdateView` au-dessus d'une feuille ouverte ; retour du focus après masquage.
- GPS réel, réseau réel, `min_version` réel en base.
- Compilation : build Release vert sur `44c6f35` (`** BUILD SUCCEEDED **`), exécuté par l'auteur.
