---
revue: R051
mandat: M0061
verdict: RESERVE
tip: 380cd8fa41611632c6386e53473053b7a6ebff8d
niveau: N3
---

# R051 -- Invitation à prendre la première photo (fiche sans photo)

Relecture indépendante (doublage N3) de la branche `feat/fiche-invitation-photo`, tip `380cd8f`, base `origin/main` (`5c87ef8`). Lecture seule, copie détachée dans le scratchpad (supprimée ensuite). Diff : 9 fichiers, 79 insertions, 7 suppressions.

## Points de contrôle

**a) Règle 1 (seul le cas « aucune photo publiée » change) : OUI.**
`Views/Components/PhotoCarousel.swift:27` : la nouvelle branche exige `photos.isEmpty && localImage == nil && !uploading`, donc l'envoi en cours et la preview locale n'entrent pas dedans. Le placeholder `.failure` (`:64-66`) est dans `pages` (`:57-96`), atteint seulement quand `photos` n'est pas vide : inchangé. La branche grise `:43` reste en repli, mais `DetailView` passe toujours un texte non vide quand `photos` est vide, donc elle n'est pas atteinte depuis la fiche.

**b) Règle 2 (texte selon la distance) : OUI.**
`Views/Detail/DetailView.swift:287` : `distance = distanceFromUser(to: box)`. `distanceFromUser` (`:491-495`) ne fait que lire `LocationService.shared.currentLocation` (`:492`), pas d'écriture. Seuil `Models/BookBox.swift:183` (`photoInviteMeters = 300`) ; `isNearPhotoInvite` (`:185`) = `(distance ?? .greatestFiniteMagnitude) <= 300`. Bornes : 300.0 => proche, 300.01 => loin, nil => loin. Texte choisi dans `DetailView.swift:498-503`.

**c) Règle 3 (toucher = bouton « Ajouter », même test) : OUI.**
`DetailView.swift:288` : `canAdd = vm.photos.count < Constants.maxPhotosPerBox (3, App/Constants.swift:18) && (distance ?? max) <= 100`, identique à `photoAddButton` (`:445-448`). Règle des 100 m non modifiée (`:447`). Action au toucher `:296` : `canAdd ? { vm.showPhotoModal = true } : nil`, identique à `:451`. Aucun nouveau circuit d'envoi (la feuille reste `:152`).

**d) Règle 4 (chaînes FR/EN, JSON valide) : OUI.**
`Localizable.xcstrings` : clés présentes avec EN exacts (« No photo yet. Passing by? Take the first one! » et « You're less than 300 m away: your photo will be the first of this box, the community already thanks you! »). `json.load` OK. Vérification programmatique : les clés FR sont byte-identiques aux littéraux `NSLocalizedString` (`DetailView.swift:500` et `:503`), aucun espace insécable (U+00A0 / U+202F) dans les clés.

**e) Règle 5 (zones critiques intactes) : OUI.**
Les 9 fichiers du diff n'incluent ni `DetailViewModel.swift`, ni `Services/LocationService.swift`, ni `Services/PhotoService.swift`, ni `App/Constants.swift` ; `git diff origin/main..380cd8f -- <chemins réels>` est vide. (Le mandat écrit `ViewModels/...` sans le préfixe `BoitesALivresNative/` ; les chemins réels ont été vérifiés.) Aucun changement de payload, endpoint ni base.

**f) Version 31 : OUI.**
`project.yml:25` `CURRENT_PROJECT_VERSION: 31`, `project.yml:24` `MARKETING_VERSION: 1.3.0`. `project.pbxproj:425` et `:508` = 31 (aucune occurrence restante de 30), `MARKETING_VERSION = 1.3.0` aux `:434` et `:517`. `CHANGELOG.md:14` « ### Build 31 ». `release-notes/en-US.txt:1` et `fr-FR.txt:1` : « Version 1.3.0 (build 31) ».

**g) Qualité Swift : NON (régression transitoire), reste OK.**
- OK : `Color(.systemGray5)` et `.secondary` sont adaptatifs (mode sombre, `PhotoCarousel.swift:29,33,36`). `contentShape` avant `onTapGesture` (`:41-42`) : zone tactile correcte. Pas de `!` de déballage ajouté, `??` avec `greatestFiniteMagnitude`. Cas photos non vides : `pages` et `onTap` inchangés.
- **NON, réserve prouvée :** pendant le chargement d'une fiche qui a des photos, la fiche affiche l'invitation « Pas encore de photo ». Scénario : `ViewModels/DetailViewModel.swift:31` assigne `box = data` avant la requête photos ; `:37` n'assigne `photos` qu'après `await`. Pendant ce temps `loading` est vrai, mais la garde de `Views/Detail/DetailView.swift:24` ne teste que `vm.loading && vm.box == nil`, donc la fausse ouverture de `photoSection` (`:285`) est rendue avec `photos == []`. Le cadre affiche donc « Pas encore de photo... » pour une boîte qui en a, et il est touchable si la distance est <= 100 m (`:288`, `vm.photos.count == 0`) : le toucher ouvre la feuille d'ajout. Avant le changement, c'était un carré gris neutre. Correctif suggéré : ajouter `!vm.loading` à la condition `emptyInvite` (`DetailView.swift:293`) et à `canAdd` (`:288`).
- Pas de warning évident repéré au relecture statique. Compilation non exécutée (pas de `xcodebuild` dans cette revue).

## Points qui ne sont pas des réserves (remarques)

- Texte « Tu es à moins de 300 m : ta photo sera la première... » affiché entre 100 m et 300 m, où le cadre n'est pas touchable (`DetailView.swift:296`, `onTapEmpty` = nil) : le texte annonce une action non offerte à cette distance. C'est la conséquence du choix produit 300 m (texte) / 100 m (action) ; à confirmer.
- Accessibilité : le cadre tactile n'a ni trait de bouton ni libellé VoiceOver d'action ; le texte est lu comme statique.

## h) Non vérifié

- Aucune capture d'écran, aucun lancement dans le simulateur, aucun rendu clair/sombre réel.
- Aucune compilation (`xcodebuild`) ni exécution de tests.
- Comportement réel de la fenêtre de chargement (point g) non reproduit à l'écran.

## Budget (`pre-commit --controle`)

Commande exécutée depuis le dépôt principal (`core.hooksPath` = `scripts/harnais-hooks`, relatif), sortie complète :

```
OK        .claude/skills/orchestration-bureau/SKILL.md : 29078 caracteres (seuil 40000), ligne la plus large 399 (seuil 400)
OK        CLAUDE.md : 45 caracteres (seuil 40000), ligne la plus large 44 (seuil 400)
OK        vault/reprise/00_INDEX.md : 1973 caracteres (seuil 80000), ligne la plus large 107 (seuil 400)
OK        vault/reprise/CARNET_DE_BORD.md : 1115 caracteres (seuil 40000), ligne la plus large 200 (seuil 400)
controle-instructions : 4 fichier(s) charge(s) d'office dans 380cd8fa41611632c6386e53473053b7a6ebff8d (base 5c87ef8685ade9cbfa28db4b2fbd725fdf910114) -- 4 OK, 0 ATTENTION, 0 BLOQUE
```
Exit 0.

## Réserves

1. **Régression transitoire (point g)** : invitation « pas encore de photo » affichée pendant le chargement d'une fiche qui a des photos, cadre touchable à <= 100 m. Preuve : `DetailViewModel.swift:31` et `:37`, `DetailView.swift:24`, `:288`, `:293`. Correctif : gate sur `!vm.loading`. Bloque le GO tant que non corrigé (ou verdict du mandat).

## Verdict

RESERVE : a) à f) OUI ; g) une réserve prouvée (ci-dessus).
