---
date: 2026-11-05
tags: [revue, reglages, alerte-proximite, doublons, onglet, build-33]
revue: R055
mandat: M0066
branche: fix/diagnostic-doublons-onglet
verdict: GO
tip: 04a68cb5bbd7bd2e73ca13923d7c60d10d194f32
niveau: N3
---

# R055 — Diagnostic caché en production, doublons du journal, retour à la racine de Réglages (build 33)

Doublage indépendant par sous-agent frais (Haiku, lecture seule) en deux passes.

## Passe 1 — tip b284065 : RÉSERVE

- Réserve prouvée (lecture du code) : le critère de réenregistrement ne comparait que la dernière demande. Si iOS arrêtait la surveillance sans changement d'ensemble, rien n'était réenregistré (`apply`, `ProximityAlertService.swift`). Au lancement avec candidats vides, les régions de la session précédente restaient surveillées.
- Test rouge : l'ancien critère renvoie `false` là où il faut `true` (scénario « surveillance perdue »). Vert avec `needsRegistration` (6/6, harnais hors dépôt sur le texte extrait du fichier réel).

## Correctif — commit 04a68cb

- `needsRegistration(chosen:registered:monitoredIds:)` compare la signature mémorisée ET les régions réellement surveillées (`manager.monitoredRegions`, préfixe `box-`).
- Second correctif sur la même classe de défaut (doublons / réenregistrement). Le mécanisme corrigé est l'état réel de la surveillance, pas une copie mémorisée.

## Passe 2 — tip 04a68cb : GO (remarques non bloquantes, suivi #74)

- Périmètre : un seul fichier pour ce commit. Règle 7 km/h et vitesse inconnue inchangées (`BookBox.swift`, `LocationRules.alertSpeedDecision`).
- Les deux scénarios de la réserve sont couverts. Pas de boucle synchrone.
- Remarques pré-existantes ou spéculatives, sans test rouge : lancement à froid sans position (régions périmées jusqu'au prochain déplacement) ; churn si iOS refuse une région ; notification d'une boîte sortie de l'ensemble en course. Suivies dans #74.

## Règles vérifiées (passe 2)

1. Diagnostic : `NavigationLink`, `ProximityDiagnosticView`, `SettingsRoute` et `.navigationDestination` sont sous `#if DEBUG` appariés. Journal non gardé (voulu).
2. Doublons : garde de `handledInside` et `inFlightBoxes` avant `ProximityJournal.add` ; `inFlightBoxes` retiré dans la fermeture ; `disable()` remet la signature à `[]`.
3. Réglages : `settingsPath` déclaré, passé, vidé à la sortie de l'onglet et au re-toucher (comme Carte et Liste).
4. Version : `CURRENT_PROJECT_VERSION = 33` (project.yml et pbxproj, Debug et Release), `MARKETING_VERSION` 1.3.0, CHANGELOG « Build 33 », release-notes : seule la ligne « build 33 ».

## Preuves exécutées (04a68cb)

- Build Release (`xcodebuild … -configuration Release … build`) : rc 0, 0 erreur.
- Build Debug : rc 0, 0 erreur.
- Release (binaire `BoitesALivresNative`, 16:15) : 0 symbole `ProximityDiagnostic|SettingsRoute`, 0 chaîne « Diagnostic des alertes ». Contrôles positifs : `needsRegistration` 1, `ProximityAlertService` 71, chaîne « Est-elle bien ici » 1.
- Debug : symboles `ProximityDiagnosticView` présents dans `BoitesALivresNative.debug.dylib` (58), chaîne présente (1).
- `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail.
- Contrôle budget instructions : 4 OK, 0 ATTENTION, 0 BLOQUE (`--controle 04a68cb… --base 8d3d143…`).
- Simulateur iPhone 17 (iOS 26.5) : Debug installé et lancé (pid observé). Journal non observé : pas de position en cache à 221 m au moins, et `apply` n'a pas été rappelé après chargement. Le double journal n'est donc PAS reproduit en simulateur.

## Non vérifié

- Comportement CoreLocation réel (persistance des régions, `monitoredRegions` après refus) : sur appareil seulement.
- Test UI du retour à la racine et de la présence du diagnostic : checklist fondateur.
