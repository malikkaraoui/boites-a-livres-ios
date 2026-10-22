---
date: 2026-10-21
revue: R033
mandat: M0040
mandat_id: M0040
branche: feat/carte-localisation
base: fa159395238d5ee2f09151912a7b5a40e7ce8d77
tip: 709afe9dcad1dd59cce407f787b7ea348ac92fdc
niveau: N3
verdict: GO
---

# R033 — Premier fix GPS jugé à l'horodatage (M0040)

## Périmètre
Diff `fa15939..709afe9`, relu en lecture seule dans le worktree détaché `F01-M0040-rev`. Le changement propre à M0040 tient dans deux fichiers : `Models/BookBox.swift` (`LocationRules.isFresh`, `LocationRules.firstFixEffect`) et `ViewModels/AddBoxViewModel.swift` (`applyFirstFix`, `returnToMap`, suppression de `autoCentered`).

## Réserve R032 levée
- `Models/BookBox.swift:226` : `isFresh` exige `timestamp >= openedAt` et `accuracy >= 0`.
- `Models/BookBox.swift:232` : `firstFixEffect` ne renvoie rien sans `isWaiting`, `onMapStep` et `isFresh`.
- `ViewModels/AddBoxViewModel.swift:54-63` : `applyFirstFix` passe par ces deux règles avant de toucher la caméra ou le repère.
- `ViewModels/AddBoxViewModel.swift:78-81` : `returnToMap` réarme `positionStepOpenedAt` et `waitingFreshFix`, donc un ancien fix ne repasse pas le filtre.

## Témoin rouge / vert (harnais hors dépôt)
Le harnais compile le vrai `AddBoxViewModel.swift`, `BookBox.swift`, `LocationService.swift` et `Constants.swift` (cible Mac Catalyst), avec un stub de `SupabaseService`. Il rejoue l'abonnement `@Published` comme `App/AddBoxView.swift`.
- Sur `34f3668` : `FAIL S2 cache ancien puis fix live (pin=48.8566,2.3522)`, `FAIL S2 caméra`, `FAIL S3`, `FAIL S5`, `FAIL S6 caméra` ; `ÉCHECS : 5`, exit 1. C'est la réserve R032 reproduite.
- Sur `709afe9` : 11 contrôles PASS, `TOUT VERT`, exit 0. Couvre le cache ancien seul, cache puis fix live, fix sans cache, deuxième fix ignoré, précision négative ignorée, « Replacer » après toucher (caméra recentrée, repère conservé), note et précision 50 m.
- Build Release iOS : `** BUILD SUCCEEDED **`. Build simulateur de contrôle (relecture) : `BUILD SUCCEEDED`.
- `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail.

## Checklist M0038 / M0039 (ligne par ligne)
- Note au-dessus du clavier, hauteur fixe, défilement : OK (`App/AddBoxView.swift` : `lineLimit(5, reservesSpace: true)`, `scrollTo("notes")`).
- Un seul saut de ligne, 100 caractères : OK (`Models/BookBox.swift` `NoteText.limitLineBreaks`, `AddBoxView.swift` `notesLimit`).
- Précision 50 m : OK (`LocationRules.canSendManual`, témoin 50 accepté, 51 refusé).
- Toucher = placer le repère (`MapReader`, `placePin`) : OK par lecture ; glisser la carte ne déplace pas le repère : OK par lecture, non vérifié à l'écran.
- Pas de vue « France entière » si une position est connue : OK (`init` du VM, 300 m).
- Aucun changement de payload, endpoint ou champ Supabase : OK (`git diff --name-only` sans `Services/`).
- Alerte de proximité non affectée : OK (`Services/ProximityAlertService.swift` et `LocationService.swift` non modifiés).
- Build 18 cohérent : OK (`project.yml` `CURRENT_PROJECT_VERSION: 18`, `project.pbxproj`, CHANGELOG, release-notes).

## Budget
`sh "$(git config core.hooksPath)/pre-commit" --controle 709afe9dcad1dd59cce407f787b7ea348ac92fdc --base fa159395238d5ee2f09151912a7b5a40e7ce8d77` : 4 OK, 0 ATTENTION, 0 BLOQUE, exit 0.

## Réserves bloquantes
Aucune.

## Remarques (non bloquantes, à traiter en issues)
1. **Fix reçu pendant le formulaire.** Un fix frais reçu pendant l'étape formulaire est ignoré (`applyFirstFix` ne traite que `step == .map`). Après « Replacer », la caméra se centre sur ce fix (`centerCameraOnGPS`), mais le repère reste à sa position par défaut : `returnToMap` ne le pose pas. Il suit au fix frais suivant, et `beginPrecisionUpdates` rend ce fix suivant probable. Preuve : sonde hors dépôt, `P1 camera on fix=true pin on fix=false pinIsDefault=true`. Ce n'est pas un test du harnais : à traiter en issue, pas de correctif dans M0040. Correctif possible : retenir le dernier fix reçu et l'appliquer au retour.
2. **Présence sur place et cache (préexistant, hors diff).** `presenceDistance` (`ViewModels/AddBoxViewModel.swift`) lit `LocationService.shared.currentLocation` sans contrôle de fraîcheur : le cache peut valider la présence. L'ancien code faisait déjà ainsi avec `canSend` ; le passage à 50 m élargit la marge. À traiter séparément : accepter la présence seulement sur un fix frais.
3. **Témoin incomplet.** Le contrôle S7 du harnais n'a aucune assertion sur la présence sur place. Le cas `timestamp == openedAt` (`>=`) n'est pas testé. Un fix daté dans le futur est accepté ; sans gravité pratique.
4. **Initialisation.** `positionStepOpenedAt = Date()` à la création du VM rejette un fix mesuré juste avant ; le fix suivant corrige la situation.

## Ce qui n'est pas testé
- Rendu et interactions réels (tap sur la carte, glisser, clavier, OK) : seulement compilation et lecture de code, pas d'exécution sur simulateur ni appareil. La validation terrain reste à faire.
- Le harnais ne compile ni `App/AddBoxView.swift` ni `ProximityAlertService.swift` ; seul le build complet les couvre, sans test de comportement.
- Présence sur place, boundary `timestamp == openedAt`, fix reçu pendant le formulaire suivi d'un « Replacer » sur appareil réel.
