---
verdict: GO
tip: 73a71ae402cbefc563aa76ea7fcfe9aef8d42868
niveau: N3
---

# R056 — relecture de publication 1.4.0 (build 34), N3

Relecture indépendante, deuxième passe. Contrôles relancés par commandes, sans conclusion reprise de la première relecture.

## Contrôles

| # | Contrôle | Commande | Résultat |
|---|---|---|---|
| 1 | Périmètre du diff | `git diff origin/main HEAD --stat` | 6 fichiers, conformes : `project.pbxproj`, `CHANGELOG.md`, `project.yml`, `release-notes/en-US.txt`, `release-notes/fr-FR.txt`, `BoitesALivresNative/Localizable.xcstrings`. `git status` : seul `vault/revues/…R056-publication-v1-NO-GO.md` non suivi (non commité, hors diff). |
| 1b | Localizable.xcstrings | `git diff origin/main HEAD -- …xcstrings` ; `python3 -c "import json;json.load(open(...))"` | Une seule suppression : bloc « Diagnostic des alertes » (17 lignes `-`, 0 `+`). Lignes modifiées = 17. `JSON OK`. |
| 2 | Numéros de version | `grep` sur `project.yml` et `project.pbxproj` ; diff CHANGELOG | project.yml : `MARKETING_VERSION: 1.4.0`, `CURRENT_PROJECT_VERSION: 34`. pbxproj : 2 occurrences de `CURRENT_PROJECT_VERSION = 34;` et 2 de `MARKETING_VERSION = 1.4.0;` (aucune 1.3.0 ou 33 restante). CHANGELOG : `## [1.4.0] - non publiée`, « Build 34. Contenu depuis la 1.3.0 (build 28, en ligne) » ; la 1.3.0 est passée en « publiée ». Cohérent. |
| 3 | Notes de version | Extraction de `vault/echanges/F01.md` (section « Notes de version », fichier lu en lecture seule dans `BoitesALivresNative/vault/echanges/`, non suivi par git), puis `diff` | `diff ref-fr.txt release-notes/fr-FR.txt` : aucune sortie (identique). `diff ref-en.txt release-notes/en-US.txt` : aucune sortie (identique). `wc -m` : fr-FR 997, en-US 835 (≤ 4000). 17 lignes chacun. |
| 4 | Chaîne absente du bundle Release | `ls .build/release-check2/Build/Products/Release-iphoneos/BoitesALivresNative.app` | **Dossier absent** (`No such file or directory`). `.build/` ne contient que `Debug-*`. Recherche de `BoitesALivresNative.app` dans le dépôt : seulement Debug et archives anciennes. Le contrôle n'a pas pu être exécuté. Non rebâti (consigne). |
| 4s | Contrôle source (complément, non substitutif) | `grep -rn "Diagnostic des alertes" . --exclude-dir=.build --exclude-dir=build --exclude-dir=.git` | Usage Swift : `BoitesALivresNative/App/SettingsView.swift:264-268` (`NavigationLink` « Diagnostic des alertes ») entouré de `#if DEBUG` / `#endif` ; second bloc `SettingsView.swift:626-662` sous `#if DEBUG`. La chaîne n'apparaît plus dans `Localizable.xcstrings`. |
| 5 | Tests ASC | `node --test scripts/release/asc.test.mjs` | `tests 17`, `pass 17`, `fail 0`, `cancelled 0`. |

## Verdict

**GO** sur le tip 73a71ae402cbefc563aa76ea7fcfe9aef8d42868.

Premier passage : NO-GO, le contrôle 4 n'avait pas pu être exécuté (bundle `release-check2` absent). Le coordinateur a rebâti le Release à l'identique du tip dans `.build/release-check3/`. Contrôle 4 relancé sur ce bundle, contrôles 1, 2, 3, 5 relancés sur le même tip : tous verts.

### Contrôle 4 (bundle `.build/release-check3/Build/Products/Release-iphoneos/BoitesALivresNative.app`)

```
$ grep -ril "diagnostic des alertes" <bundle>        -> aucune sortie, rc=1 (aucun fichier)
$ find <bundle> \( -name '*.strings' -o -name '*.plist' -o -name '*.stringsdict' \) | wc -l   -> 5
  (4 .strings : en.lproj/Localizable.strings, en.lproj/InfoPlist.strings,
   fr.lproj/Localizable.strings, fr.lproj/InfoPlist.strings ; + Info.plist)
$ plutil -convert xml1 -o - <f> | grep -c "Diagnostic des alertes"   -> 0 pour les 5 fichiers
$ plutil -convert xml1 -o - fr.lproj/Localizable.strings | grep -c "<key>"  -> 209 (scan non vide)
$ plutil -convert xml1 ... (4 .strings) -> rc 0, parsing OK
```

### Contrôles 1, 2, 3, 5 (tip 73a71ae, relancés)

- 1 : `git diff origin/main HEAD --stat` -> 6 files changed, 42 insertions, 55 deletions ; xcstrings : une suppression de 17 lignes, JSON valide.
- 2 : project.yml 1.4.0 / 34 ; pbxproj `MARKETING_VERSION = 1.4.0;` et `CURRENT_PROJECT_VERSION = 34;` (2 occurrences chacun) ; CHANGELOG 1.4.0 build 34.
- 3 : `diff` fr-FR et en-US contre la référence extraite de F01.md : identiques (997 et 835 caractères, ≤ 4000).
- 5 : `node --test scripts/release/asc.test.mjs` -> pass 17, fail 0.

## Réserves (défauts prouvés par commande)

- Aucune réserve de contenu : contrôles 1, 2, 3, 5 passent sans écart.
- Point à surveiller, non bloquant : la chaîne reste dans `CHANGELOG.md` (lignes 16 et 129) et dans le source sous `#if DEBUG`. Ce n'est pas un défaut de bundle Release.
- Le fichier `vault/revues/2026-11-05-R056-publication-v1-NO-GO.md` est non suivi dans le worktree, hors diff. Non commité par cette relecture.
