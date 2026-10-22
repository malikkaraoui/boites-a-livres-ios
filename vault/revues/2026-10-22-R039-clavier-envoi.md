---
date: 2026-10-22
tags: [revue, clavier, envoi, build-24, issue-55]
verdict: GO
tip: da05f7aff067cb09dc07118cb3af0530e40dea2c
niveau: N3
---

# R039 -- Fermer le clavier à l'envoi (M0047, correctif #55, build 24)

Doublage N3 par relecteur frais (Haiku), lecture seule, sur le tip `da05f7a`, base `1dd48f0`.

## Vérifié

- Bouton actif, 4 formulaires : `dismissKeyboard()` est appelé avant l'envoi dans `ReviewSubmitSheet.swift:466`, `DeletionRequestSheet.swift:160`, `AddBoxView.swift:357`, `LocationUpdateSheet.swift:289`.
- Aucun cinquième formulaire d'envoi : les champs de saisie et les appels d'envoi se trouvent tous dans les 4 formulaires.
- Bouton grisé : comportement M0045 inchangé ; fermeture seulement si le manque n'est pas un champ texte (`ReviewSubmitSheet.swift:471`).
- `SubmissionSuccessView.swift` ne contient aucun champ de saisie.
- Payload, endpoints et arguments : `Services/SupabaseService.swift` absent du diff ; seules des lignes de version changent.
- Build 24 cohérent : `project.yml:25`, `project.pbxproj:361` et `:444`, `CHANGELOG.md` (« Build 24 »), `release-notes/fr-FR.txt` et `en-US.txt`.
- Budget : `controle-instructions` 4 OK, 0 ATTENTION, 0 BLOQUE.

## Résiduels (issue #56, non bloquants)

- Garde générique absente sur les chemins grisés d'`AddBoxView` et de `LocationUpdateSheet`.
- Cas `.proximity` ou `.condition` avec `.comment` également manquant : le clavier se ferme.
- Erreur réseau après fermeture anticipée : saisie à vérifier.
- Commentaire « Manque GPS ou distance » omet `.photo`.
- Notes de version sans mention du correctif clavier.

## Non vérifié ici (simulateur ou appareil)

- Fermeture du clavier avant l'overlay de succès, sans flash.
- Resynchronisation de `@FocusState` après `resignFirstResponder`.
- Comportement avec « Réduire les animations ».
