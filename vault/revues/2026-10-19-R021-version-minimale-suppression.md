---
verdict: RÉSERVE
tip: cd418fcabc25829fab1710163863922290bd813f
niveau: N3
---

# R021 -- Doublage indépendant : version minimale + suppression à 100 m (M0026, tip cd418fc)

Relecture par sous-agent frais, lecture seule, sur `origin/main...cd418fc`.

## Verdict

**RÉSERVE.** Réserve R020 (écran sous une modale) levée par la fenêtre dédiée `UIWindow` (AppVersionGate.swift:41-49).

## Constat bloquant (C2) -- corrigé en chaîne par R022

Le swipe « Supprimer » de la liste (`App/ListView.swift:46-49`) ouvrait `DeletionRequestSheet` sans garde de
distance : un utilisateur à 5 km pouvait envoyer une demande de suppression depuis la liste, alors que la règle
(« Signaler une suppression » actif à 100 m ou moins) ne s'appliquait qu'à la fiche. Vérifié par la session mère.
Correctif : commit `44c6f35` (`.disabled(!canReportDeletion(box))`, même règle `LocationRules.canReportDeletion`).

## Autres constats

- C1 (faible, théorique) : `blockingWindow` non recréée si la scène disparaît. Pas de multi-scène déclaré dans le projet.
- Lecture en échec : `catch` ne touche pas `mustUpdate` (OK). Comparaison numérique OK. Lien App Store OK.
- Suppression à la fiche : seuil `<= 100`, position inconnue grisée, texte exact (OK). Photo inchangée à 100 m.
- Aucune écriture en base : une seule requête GET `app_config` (OK).

## Non testé

- Rendu réel de l'écran et superposition sur une modale ouverte (aucun simulateur utilisé).
- GPS réel, réseau réel, comportement `min_version` en base.
