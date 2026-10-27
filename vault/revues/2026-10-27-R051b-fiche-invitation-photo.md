---
revue: R051b
mandat: M0061
verdict: RESERVE
tip: 9dddc79ae2fad703b074198a28ba16695fc51e78
niveau: N3
---

# R051b -- Invitation à prendre la première photo (fiche sans photo), re-relecture

Relecture indépendante (doublage N3) du tip `9dddc79`, base `origin/main` (`5c87ef8`). Lecture seule, copie détachée dans le scratchpad (supprimée ensuite). Diff : 9 fichiers, 81 insertions, 7 suppressions. Rapport précédent : `vault/revues/2026-10-27-R051-fiche-invitation-photo.md` (non modifié).

## Points de contrôle

**A) Correctif de la réserve précédente : NON.**
Le correctif (`DetailView.swift:289-290`, `showInvite = !vm.loading && vm.photos.isEmpty`, `:297-298`) est bien posé, mais la branche d'invitation est **inatteignable**. `photoSection` n'est rendu que si `DetailView.swift:31` : `if !vm.photos.isEmpty || vm.localPhotoImage != nil || vm.uploading`. Cette garde est inchangée depuis `origin/main` (`git show origin/main:...DetailView.swift` ligne 31 identique). Or la branche d'invitation de `PhotoCarousel.swift:27` exige `photos.isEmpty && localImage == nil && !uploading`, soit la négation exacte de la garde. Les deux ne peuvent pas être vraies ensemble.
Scénario concret : on ouvre une boîte sans photo publiée. `vm.photos == []`, pas de preuve locale, pas d'envoi : `photoSection` n'est pas appelé, aucun cadre, aucune invitation. La fiche chargée sans photo n'affiche donc pas l'invitation (le texte « Pas encore de photo… » et la feuille d'ajout restent inaccessibles). Le cas « fiche chargée sans photo » demandé au point A n'est pas satisfait. La révue R051 avait classé la réserve « chargement » comme la seule ; cette régression de fonctionnalité était non détectée.
Chargement (`DetailViewModel.swift:30-31` : `loading = true`, `defer { loading = false }`) : la garde `!vm.loading` ne change rien au point précédent, le résultat est le même. La réserve « chargement » de R051 est donc sans effet tant que la garde `:31` n'est pas corrigée.
Correctif suggéré (à arbitrer par l'orchestrateur) : étendre la garde `:31` pour que `photoSection` soit rendu quand la fiche est chargée et sans photo (par exemple ajouter `|| !vm.loading`), tout en gardant `showInvite` pour ne pas afficher l'invitation pendant le chargement. Attention : sans `showInvite`, le cadre gris de `PhotoCarousel.swift:43` apparaîtrait pendant le chargement, ce qui est un changement de comportement à valider.

**B) Règle 1 (seul « aucune photo publiée » change) : OUI.**
`PhotoCarousel.swift:27` : la nouvelle branche exige `photos.isEmpty && localImage == nil && !uploading`. Le placeholder `.failure` (`:64-66`) est dans `pages` (`:57-96`), atteint seulement si `photos` n'est pas vide : inchangé. L'envoi en cours (`uploading`) et la preview locale ne passent pas dans la nouvelle branche. Note : la branche grise `:43` reste atteignable si `emptyInvite == nil` ; depuis la fiche, `emptyInvite` n'est pas nil quand `photos` est vide, mais voir point A.

**C) Règle 2 (texte selon la distance, seuil 300 m) : OUI.**
`DetailView.swift:287` : `distance = distanceFromUser(to: box)`. `BookBox.swift:183` : `photoInviteMeters = 300`. `BookBox.swift:185` : `isNearPhotoInvite(distance:) = (distance ?? .greatestFiniteMagnitude) <= 300`. Bornes : 300.0 => proche, 300.01 => loin, nil => loin. Choix de texte : `DetailView.swift:499-505` (`photoInviteText`).

**D) Règle 3 (toucher = ouvrir l'ajout, mêmes conditions) : OUI, sous réserve du point A.**
`DetailView.swift:288` : `canAdd = photos.count < Constants.maxPhotosPerBox && (distance ?? max) <= 100`, identique à `photoAddButton` (`:447-450`). Action `:298` : `showInvite && canAdd ? { vm.showPhotoModal = true } : nil`, équivalente à `photoAddButton` (`:453`). Règle des 100 m inchangée. Aucun nouveau circuit d'envoi. Le test est correct, mais le toucher n'est jamais atteint tant que `:31` n'est pas corrigé.

**E) Règle 4 (chaînes FR/EN, JSON valide, clés = littéraux) : OUI.**
`Localizable.xcstrings` : parse JSON OK (`python3 -I`). Les deux clés FR sont présentes (`strings[...]`) et correspondent aux littéraux `NSLocalizedString` de `DetailView.swift:502` et `:504`. Valeurs EN : « No photo yet. Passing by? Take the first one! » et « You're less than 300 m away: your photo will be the first of this box, the community already thanks you! », exactes.

**F) Règle 5 (zones critiques intactes) : OUI.**
`git diff origin/main..9dddc79 -- BoitesALivresNative/ViewModels/DetailViewModel.swift BoitesALivresNative/Services/LocationService.swift BoitesALivresNative/Services/PhotoService.swift BoitesALivresNative/App/Constants.swift` : sortie vide. Chemins réels avec préfixe `BoitesALivresNative/`, vérifiés.

**G) Version 31 : OUI.**
`project.yml:24` `MARKETING_VERSION: 1.3.0`, `:25` `CURRENT_PROJECT_VERSION: 31`. `project.pbxproj:425` et `:508` = 31, `:434` et `:517` = `MARKETING_VERSION = 1.3.0`. `CHANGELOG.md:14` « ### Build 31 ». `release-notes/en-US.txt` et `fr-FR.txt` : « Version 1.3.0 (build 31) ».

**H) Qualité Swift (risque réel uniquement) : une réserve, celle du point A.**
Compilation non rejouée (build Release en amont, non refait). Relecture statique : pas d'autre risque de compilation repéré (`if ..., let invite = emptyInvite` valide ; `??` avec `greatestFiniteMagnitude`, pas de `!`). Le risque réel est fonctionnel (A), pas de compilation.

**I) Non vérifié à l'écran :** aucune capture, aucun lancement simulateur, aucun rendu clair/sombre, aucun test du toucher ni de la fenêtre de chargement réelle. Le point A est établi par lecture de code (gardes contradictoires), ce qui suffit pour conclure à NON, mais le comportement réel n'a pas été observé.

## Réserves prouvées

1. **Invitation jamais affichée (point A).** `Views/Detail/DetailView.swift:31` (garde de `photoSection`) est la négation de la condition de `Views/Components/PhotoCarousel.swift:27` (branche d'invitation). Scénario : boîte sans photo publiée, fiche ouverte : aucun cadre, aucune invitation, aucune feuille d'ajout. Bloque le GO. Correctif : voir point A.

## Budget (`pre-commit --controle`)

Commande exécutée depuis le dépôt principal (`core.hooksPath` = `scripts/harnais-hooks`, relatif), sortie :

```
OK        .claude/skills/orchestration-bureau/SKILL.md : 29078 caracteres (seuil 40000), ligne la plus large 399 (seuil 400)
OK        CLAUDE.md : 45 caracteres (seuil 40000), ligne la plus large 44 (seuil 400)
OK        vault/reprise/00_INDEX.md : 1973 caracteres (seuil 80000), ligne la plus large 107 (seuil 400)
OK        vault/reprise/CARNET_DE_BORD.md : 1115 caracteres (seuil 40000), ligne la plus large 200 (seuil 400)
controle-instructions : 4 fichier(s) charge(s) d'office dans 9dddc79ae2fad703b074198a28ba16695fc51e78 (base 5c87ef8685ade9cbfa28db4b2fbd725fdf910114) -- 4 OK, 0 ATTENTION, 0 BLOQUE
```
Exit 0.

## Nettoyage

Copie détachée supprimée (`git worktree remove --force`), `git worktree prune` exécuté. Aucun commit, aucun push, aucune écriture hors de ce rapport.

## Verdict

RESERVE. A) NON (réserve prouvée : invitation inatteignable). B) à G) OUI. H) même réserve que A. I) non vérifié à l'écran.
