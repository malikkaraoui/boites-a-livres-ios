---
verdict: GO
tip: c1cb1e712dcb14b1b40b91bca0059a594bbf759e
niveau: N3
mandat: M0049
issue: "#58"
base: 35a7baa9adb35e02e5456f9334049107eb4cf444
---

# R041 — Retrait « Vider le cache » ; mode sombre des formulaires ; build 26

Relecture indépendante (sous-agent frais, lecture seule) de `35a7baa..c1cb1e7`.

## Constats
- A (retrait du vidage) : bouton, alerte et `cacheSection` retirés ; symboles morts absents ; `clear()` des caches sans appelant ; chaînes FR/EN retirées ; `.strings` valides (`plutil -lint`).
- B (mode sombre) : `Color.formField` = `systemGray6` en clair, `tertiarySystemBackground` en sombre. Appliqué à l'avis (nombre de livres, nom, commentaire) et à la demande de suppression. Pas de fond fixe restant dans les formulaires.
- C (payload) : aucun fichier Supabase/réseau/Apple modifié.
- D (version 26) : `project.yml`, pbxproj (2 occurrences), CHANGELOG, notes FR/EN cohérents.
- E (relecture statique) : pas d'erreur de type ou de portée relevée.

## Réserves
Aucune.

## Remarques (non bloquantes)
- Fonds `systemGray6` hors périmètre (`BookBoxSheet`, `PhotoCarousel`, `DetailView`, `ListView`) : adaptatifs, à traiter seulement si un rendu sombre les rend illisibles.

## Non vérifié par la revue
- Rendu visuel clair/sombre : pas de capture (simulateur éteint, écran d'avis derrière une boîte à moins de 100 m et des données réelles). Contraste de `tertiarySystemBackground` sur la feuille à confirmer sur l'iPhone.
- Le relecteur a fait une relecture statique ; le build Release a été lancé par l'auteur (`BUILD SUCCEEDED`, 17/17 tests `asc`).
