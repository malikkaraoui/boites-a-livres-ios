---
date: 2026-10-18
tags: [revue, photos, carrousel, ios, N3]
session: F02
mandat_id: R010
verdict: GO
tip: 66123e859df2a44c284b16b7ebfb1500a192cdd8
niveau: N3
---

# Revue R010 — `fix/photos-validees` (M0010, 1.3.0 build 9)

Doublage N3 indépendant, session F02, worktree détaché lecture seule `.claude/worktrees/F02-R010` au tip `66123e8`. Auteur : F01 / M0010.

**Verdict : GO sur le code. Le merge est BLOQUÉ** : conflit sur `vault/reprise/F01.md` lors du `merge --no-ff` (voir plus bas). Rien n'a été poussé sur `main`.

## Verdict par axe

| Axe | Verdict | Raison vérifiée |
|---|---|---|
| Symptôme (a) : photos validées affichées | ✅ | `listPhotos` lit `book_box_photos` ordonné par slot (`SupabaseService.swift` l.130-145). Lecture anon réelle `book_box_photos?box_id=eq.14183` : HTTP 200, 3 lignes (slot 1 `14183/1.jpg`, slot 2 `14183/2.jpg`, slot 3 `approved/14183/…`). Les slots 1-2 hors `approved/` : remarque n°4. |
| Symptôme (b) : plus aucune photo en attente lue | ✅ | `git -C … grep` : aucun `storage/v1/object/list` ni préfixe de stockage dans `BoitesALivresNative/`. Seules les écritures d'upload utilisent le bucket. |
| Symptôme (c) : pas de carré gris si une autre photo existe | ✅ code, ⚠️ écran | Carrousel et plein écran retirent les URL en échec (`deadURLs`), le carré gris ne reste que s'il ne reste rien (`PhotoCarousel.swift`). Aperçu carte : bascule sur la première photo validée, sinon masque le bloc (`BookBoxSheet.swift`). Remarques n°1, n°2. |
| Symptôme (d) : limite de 3 compte les slots validés | ✅ | `photos` = slots + `photo_url` si absente (fusion `PhotoList.merge`). Limite et compteur « publiées » lisent `vm.photos` (`DetailViewModel.swift` l.61, `DetailView.swift` l.376, 396). Remarque n°3 sur l'affichage de 4. |
| Sûreté | ✅ | Aucune clé dans le diff ni dans ce rapport. `try?` de `listPhotos` : remarque n°6 (silencieux, pas critique). Aucun chemin d'aléa ou de clé touché. |
| Tests | ✅ | Harnais de l'auteur (6 cas) : `ALL PASS`, exit 0, rejoué sur le code du tip. Harnais indépendant (9 cas, extraction `git show 66123e8:…/BookBox.swift`) : `ALL PASS`, exit 0. Aucune cible de tests : remarque n°5. |
| Build Release | ✅ | `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` : `** BUILD SUCCEEDED **`. Le « error: » du log est le bruit CoreSimulator « out of date », pas une erreur de compilation. |
| Version et CHANGELOG | ✅ | `CURRENT_PROJECT_VERSION` 8 → 9 dans `project.yml` et 2 occurrences du `.pbxproj`. `MARKETING_VERSION` 1.3.0 inchangé. `CHANGELOG.md` `[1.3.0]` « Build 9 » avec entrée « Corrigé ». |
| Budget fichiers chargés d'office | ✅ | `pre-commit --controle 66123e8 --base 5da85f2` : 4 fichiers OK, 0 ATTENTION, 0 BLOQUE, rc 0. |
| UX à l'écran | ⚠️ non vérifié à l'écran | Aucun simulateur démarré, pas d'iPhone dans la session. Pas de capture. Non bloquant selon le mandat (règle projet). Checklist fondateur ci-dessous. |

## Garde d'entrée

- `origin/fix/photos-validees` = `66123e859df2a44c284b16b7ebfb1500a192cdd8` : OK.
- `main` = `origin/main` = `da6e45f265e18fbf7c160cef7bb0d1f3cb6e4a77` : OK.
- `git log 5da85f2..origin/main -- <chemins du diff>` : vide. Fichiers intacts côté `main`.
- `F02.md` (le mandat) n'est pas commité (`git log -1 -- vault/echanges/F02.md` vide). Constat, pas un bloqueur : le mandat vit dans le dépôt de travail.

## Merge : STOP, conflit de registre

Le scratch `.claude/worktrees/F02-merge` (détaché sur `origin/main`) a donné, pour `git merge --no-ff 66123e8` :

- Un seul fichier en conflit : `vault/reprise/F01.md`, marqueurs aux lignes 4, 40 et 54 du fichier fusionné.
- Les deux côtés réécrivent entièrement le fichier : côté `main`, la reprise de M0011 (R009 intégré, 38 lignes) ; côté tip, la reprise de M0010 (16 lignes). L'ancêtre commun est la reprise de R008 (13 lignes). Ce n'est ni un ajout ni un fichier généré : selon le gabarit §9, c'est un STOP.
- Aucun chemin de code n'a changé sur `main` depuis le merge-base (hors `vault/`, `.claude/skills/`, `config/`, `scripts/`). Le code du tip reste donc celui qui a été testé.
- `git merge --abort` exécuté dans le scratch, puis retrait du scratch. `main` et `origin/main` sont restés à `da6e45f`.

**Décision à prendre par l'orchestrateur.** Mon choix, si on me le demandait : garder la version `main` de `vault/reprise/F01.md` (la plus récente, M0011), et déplacer le texte de la reprise M0010 dans le rapport archivé de M0010 (`vault/echanges/archive/2026-10-18-F01-M0010-photos-validees.md`, déjà committé sous son nom). Raison : le registre de reprise ne porte que l'état le plus récent d'une fenêtre ; la fusion « garder les deux » mettrait deux états contradictoires dans le même fichier. Une fois la décision prise, il suffit de relancer le merge sur ce tip, en rejouant build et harnais sur le scratch avant le `ff-only`.

## Remarques (non bloquantes, issues ouvertes)

1. Annulation ou timeout de chargement → photo valide retirée définitivement de la vue : https://github.com/malikkaraoui/boites-a-livres-ios/issues/12
2. Aperçu carte : bascule sur la même photo morte (cas slot 1 = `photo_url`) ; hauteurs de feuille `MapScreen` / `ListView` avec `photo_url` morte : https://github.com/malikkaraoui/boites-a-livres-ios/issues/13
3. Limite « 3 » et affichage à 4 quand `photo_url` est hors slots : décision fondateur : https://github.com/malikkaraoui/boites-a-livres-ios/issues/14
4. Données : slots 1-2 sous `<boxId>/`, et photos en attente lisibles par URL directe (dépôt admin) : https://github.com/malikkaraoui/boites-a-livres-ios/issues/15
5. Aucune cible de tests ; `PhotoList.merge` non couvert en CI : https://github.com/malikkaraoui/boites-a-livres-ios/issues/16
6. `listPhotos` avale toute erreur sans trace : https://github.com/malikkaraoui/boites-a-livres-ios/issues/17

## Checklist fondateur (sur iPhone, build depuis `fix/photos-validees`)

1. Boîte #14183, ouvrir le détail : le carrousel montre les photos validées (3 attendues) et aucune photo en attente.
2. Boîte #14183, ouvrir le plein écran et glisser entre les photos : aucun carré gris.
3. Une boîte à 1 photo validée : le carrousel montre 1 photo, le bouton affiche « 1/3 publiées ».
4. Boîte avec 3 photos validées : « Maximum 3 photos atteint » s'affiche.
5. Carte : toucher une boîte dont `photo_url` est morte : l'aperçu montre la première photo validée, ou pas de bloc image.

## Ce que je n'ai PAS testé

- Rendu réel à l'écran, chargements lents, annulations de tâche (remarque n°1) : aucun simulateur ni appareil.
- Appel complet `listPhotos` de l'app (seule la requête REST a été lue, avec la clé anon, non affichée).
- Droits d'écriture Supabase : volontairement absents (mandat : lecture seule).
- Migration ou nettoyage des photos en attente : hors périmètre.
