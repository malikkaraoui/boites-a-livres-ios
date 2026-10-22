---
date: 2026-10-23
revue: R047
mandat: M0055
branche: test/ui-audit
niveau: N3
verdict: GO
tip: 452cbb1d0e7fee7aedca6adfc2c35cae645fad08
---

# Revue R047 — tests d'interface (M0055)

Relecture indépendante de la branche `test/ui-audit` (base `b8bec8f`, tip relu `452cbb1`), par deux sous-agents frais en lecture seule.

## Première passe (tip 4fae40b) — RESERVE

Réserve prouvée : la feuille Localisation géocode à son ouverture (`LocationUpdateSheet.swift`, `onAppear` → `centerOnBox` → `CLGeocoder`), et le test l'ouvrait. Corrigé dans `452cbb1` : le test ne l'ouvre plus et la note « NON ATTEINT ». Le rapport d'audit est corrigé en conséquence.

## Seconde passe (tip 452cbb1) — GO

- Réserve corrigée : aucune action du test n'ouvre la feuille Localisation ni ne touche ses boutons d'envoi.
- Actions du test passées une par une : aucun géocodage (`CLGeocoder`) ni recherche MapKit déclenchés. « Confirmer la position » n'est jamais touché. La bascule d'alerte ne fait que désactiver puis annuler ; « Continuer » n'est jamais touché.
- Aucun envoi de formulaire : `avis-envoyer` est touché sur un formulaire incomplet, qui ne soumet pas ; `suppression-envoyer` et `localisation-envoyer` ne sont jamais touchés.
- Aucun changement de payload : aucun fichier Supabase, service ni modèle modifié.
- Hooks entièrement sous `#if DEBUG` ; hors DEBUG, le comportement est inchangé (seuls des identifiants d'accessibilité ont été ajoutés).
- Script rejouable : `bash -n` passe ; la garde de suppression ne touche que les dossiers créés par `mktemp`.
- Rapport cohérent : 32 captures, 8 par passe.

## Points d'interprétation et remarques (non bloquants, ouverts en issues)

- Tuiles MapKit : l'onglet Carte et la carte de l'étape 1 de l'ajout chargent des tuiles Apple. Le mandat n'interdit que le géocodage, la recherche, APNs et StoreKit. Issue #60.
- Le schéma partagé inclut désormais la cible de tests : `make test` lance aussi l'audit visuel. Issue #61.
- `scripts/ui-audit.sh` : le `find -delete` s'exécute avant le `mkdir` du dossier de sortie ; sur un dossier absent, le script s'arrête avant l'export. Issue #61.
- L'état « Alerte près d'une boîte » n'est pas rétabli entre les passes. Issue #61.

## Vérifications sur le résultat du merge

- Build Release (`CODE_SIGNING_ALLOWED=NO`) : exit 0.
- `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail.
- Tests d'interface : 4 passes vertes sur `452cbb1` (32 captures), voir `vault/revues/2026-10-23-audit-build-27.md`.
