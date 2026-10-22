---
date: 2026-10-23
revue: R048
mandat: M0056
branche: fix/build-28-affichage
niveau: N3
verdict: GO
tip: 22d674bff78517a757c0ee5bd9370291fa270696
---

# Revue R048 — numéro de boîte et département (M0056, build 28)

Doublage indépendant de la branche `fix/build-28-affichage` (base `5b6fd43`, tip relu `22d674b`), par des sous-agents frais (Haiku) en lecture seule, sur worktrees détachés. Aucun fichier du dépôt modifié par les relecteurs.

## Première passe (tip `05618fd`) — RÉSERVE

Réserve prouvée : quatre valeurs anglaises du catalogue `BoitesALivresNative/Localizable.xcstrings` gardaient `%lld` alors que le code passe une chaîne (`String(boxId)`, `ProximityAlertService.swift:89, 94, 97, 99`) :

- `dans le rayon de la boîte %@ (%@)` → en `within range of box %lld (%@)`
- `notification envoyée : boîte %@` → en `notification sent: box %lld`
- `notification bloquée : boîte %@, anti-répétition 30 j` → en `notification blocked: box %lld, 30-day repeat guard`
- `anti-répétition posée : boîte %@, 30 j` → en `repeat guard set: box %lld, 30 days`

Vérifié à la lecture avant correction. Corrigé dans `22d674b` : les quatre valeurs passent en `%@`.

Autres constats de la première passe, tous vérifiés et non bloquants : valeur `department` faite d'espaces seuls, clé obsolète `Boîte #%lld`, codes `20` et `975` affichés tels quels, apostrophes droites, traduction fr de `#%@ — %@` en `state: new`. Consignés dans l'issue #64.

## Seconde passe (tip `22d674b`) — GO

- **Concordance des spécificateurs** : script de contrôle sur les 428 clés (fr + en), zéro mismatch, sortie collée par le relecteur. Limite connue : le script vérifie la cohérence interne du catalogue ; le contrôle code ↔ catalogue est fait à part (point suivant).
- **Clés corrigées** : `grep` des quatre clés, aucune valeur anglaise ni française ne contient `%lld`.
- **Appels** : les quatre arguments interpolés sont des `String(boxId)` ; les littéraux Swift correspondent octet pour octet aux clés du catalogue (vérifié avec `k in cat`).
- **Recherche de nouvelle réserve de même classe** : aucune. Les `%lld`/`%d` restants sont tous des affichages dont la clé existe, ou des messages techniques. Une remarque non bloquante : `ReviewSubmitSheet.swift:258` utilise `%d` avec un `Int` ; `%lld` serait exact (consignée, à traiter dans l'issue #64).
- **Budget de contrôle** : `sh "$(git config core.hooksPath)/pre-commit" --controle 22d674b --base 5b6fd43` → 4 OK, 0 ATTENTION, 0 BLOQUE.

## Passe initiale, axes conservés

- **Identifiant de boîte** : tous les sites d'affichage recensés passent par `String(...)` (`ListView.swift:209`, `SettingsView.swift:596`, `DetailView.swift:85, 106, 522`, `BookBoxSheet.swift:68`, `ReviewSubmitSheet.swift:308`, journal `ProximityAlertService.swift:89-99`). Les notifications locales (titre et corps) ne contiennent pas le numéro.
- **Département** : `Models/Departements.swift`, 101 entrées (96 métropolitaines dont 2A et 2B, plus 971, 972, 973, 974, 976 ; 975 volontairement exclu, collectivité), noms vérifiés un à un, aucune faute relevée. `DetailView.swift:55-56` n'affiche plus la valeur brute.
- **Aucun changement de payload** : `git diff --stat 5b6fd43 22d674b` sur `Services/`, `ViewModels/`, `LocationUpdateSheet.swift` ne touche que `ProximityAlertService.swift` (enveloppement `String(boxId)`, 4 lignes).
- **Version 28** : `project.yml:25`, `project.pbxproj` (Debug et Release), `CHANGELOG.md` « Build 28 », `release-notes/*.txt` « build 28 », aucune puce.

## Verdict

GO au tip `22d674bff78517a757c0ee5bd9370291fa270696`. Aucune réserve prouvée ouverte.
