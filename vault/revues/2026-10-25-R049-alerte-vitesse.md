---
date: 2026-10-25
revue: R049
mandat: M0059
branche: fix/alerte-vitesse-7kmh
niveau: N3
verdict: GO
tip: 5a616d79db359639dfa750749245328fb4e536fa
---

# Revue R049 — alerte de proximité à 7 km/h (M0059, build 29, issue #65)

Relecteur : sous-agent frais (Haiku), worktree détaché en lecture seule, sans build ni test (aucune cible de tests unitaires dans `project.yml`).

## Verdict : GO

Aucune réserve prouvée. Les trois cas (notify, tooFast, unknown) se comportent comme la spec sur les deux chemins (entrée, état « dedans »). Aucune anti-répétition n'est posée hors du chemin notify. Version 29 cohérente (project.yml, pbxproj, Info.plist, release-notes). Le JSON de `Localizable.xcstrings` est valide.

## Remarques non bloquantes (deviennent des issues, pas un nouveau tour)

- Piéton immobile : `speed < 0` donne `unknown`, donc aucune alerte, et une position fraîche sans vitesse valide ne relance pas de requestLocation précis. Cas conforme à la spec, à vérifier sur appareil.
- Une position grossière de `didUpdateLocations` résout une demande en attente sans contrôler `horizontalAccuracy`.
- Arrivée en voiture puis marche dans le rayon : pas de nouvelle alerte tant qu'on n'est pas sorti puis rentré. Conséquence de la spec ; la phrase « l'alerte reste possible à pied » de CHANGELOG Build 29 est donc exagérée.
- Chaque `didUpdateLocations` relance `apply()` et des requestLocation répétés en voiture : coût batterie et journal rempli de lignes « en mouvement ».
- Une sortie pendant la fenêtre de 10 s n'annule pas la notification (pas de revérification d'appartenance à la région).
- Cosmétique : clés `extractionState: "stale"` dans le catalogue ; `print` de didFailWithError hors journal.

## Non vérifié par la revue

Compilation et tests (faits par l'orchestrateur, voir le rapport M0059). Comportement réel de CoreLocation (fréquence de `speed = -1`, suspension iOS pendant la temporisation). Interaction avec `LocationService.swift`, autre CLLocationManager non examiné en détail.
