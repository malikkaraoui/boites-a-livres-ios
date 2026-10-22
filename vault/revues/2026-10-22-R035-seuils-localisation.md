---
verdict: GO
tip: 2e87c538b6d4cc372bb2b3b06bdee7d89fe3e761
niveau: N3
---

# R035 : seuils de localisation (commit 2e87c53, base 1436bae)

Relecture indépendante, lecture seule. Worktree de revue détaché sur le tip, retiré à la fin.

## Budget (`pre-commit --controle`)

```
OK        .claude/skills/orchestration-bureau/SKILL.md : 29078 caracteres (seuil 40000), ligne la plus large 399 (seuil 400)
OK        CLAUDE.md : 45 caracteres (seuil 40000), ligne la plus large 44 (seuil 400)
OK        vault/reprise/00_INDEX.md : 1973 caracteres (seuil 80000), ligne la plus large 107 (seuil 400)
OK        vault/reprise/CARNET_DE_BORD.md : 1115 caracteres (seuil 40000), ligne la plus large 200 (seuil 400)
controle-instructions : 4 fichier(s) charge(s) d'office dans 2e87c538b6d4cc372bb2b3b06bdee7d89fe3e761 (base 1436bae51e66c20da3d45779fef409203bc79fdc) -- 4 OK, 0 ATTENTION, 0 BLOQUE
EXIT=0
```

## Règles, fichier:ligne

Fichiers par défaut : `BoitesALivresNative/` (sous-dossier Swift), abrégés `Models/BookBox.swift` et `Views/Components/LocationUpdateSheet.swift`.

| # | Règle | Fichier:ligne | Verdict | Preuve |
|---|---|---|---|---|
| 1 | `moveMinMeters = max(20, 2 × accuracy)` | `Models/BookBox.swift:225-227` | Conforme | `moveFloorMeters = 20`, `max(moveFloorMeters, 2 * accuracy)`. Test : acc 5 → 20, acc 15 → 30, acc 10.2 → 20.4. |
| 1 | `locationAction` pure, `confirm`/`move`/`blocked(raison)` | `Models/BookBox.swift:230-247` | Conforme | Fonction `static`, sans état. `pinDistance > moveMinMeters` → `.move`, sinon `.confirm`. Égalité au seuil → `.confirm` (test : écart 20 à acc 5 → confirm ; 20.001 → move). |
| 1 | Repère bougé sous le seuil reste `.confirm` | `LocationUpdateSheet.swift:46-50` | Conforme | `kind` ne vaut `.move` que si `action == .move`. |
| 2 | Confirmation : téléphone ≤ 50 m ET précision ≤ 50 m | `BookBox.swift:243-245`, `LocationUpdateSheet.swift:52, 57-60` | Conforme | `presenceMeters = 50` (`BookBox.swift:182`), `canSendManual` (≤ 50, ≥ 0). Pas de ≤ 10 m restant pour la confirmation. Test : tel 50 → confirm, 50.0001 → tooFar ; acc 50 → confirm, 50.0001 → badAccuracy, acc -1 → badAccuracy. |
| 2 | `source` gps seulement si précision ≤ 10 m | `BookBox.swift:262-263` | Conforme | `(canSend(accuracy) && pinIsGPS) ? "gps" : "manual"`, avec `canSend` = `0 ≤ acc ≤ 10`. Les deux seuls appels `insertLocationUpdate` (`LocationUpdateSheet.swift:317-321` et `326-330`) passent par `source(...)`. Aucun `"gps"` en dur ailleurs (grep). |
| 2 | Contrainte serveur respectée | `BoitesALivres/supabase/migrations/20261019180000_location_updates_precision_manuelle.sql` (autre dépôt) | Conforme | Contrainte : `accuracy_m` nul, ou `[0,10]`, ou `coalesce(source='manual',false)` et `[0,50]`. Côté client, un envoi exige `canSubmit` (donc `acc ∈ [0,50]`, cf. ligne 3). `gps` n'est émis que si `acc ≤ 10`. Aucun chemin ne produit `gps` au-delà de 10 m ni un `accuracy_m` hors `[0,50]`. |
| 2 | Aucune migration, payload, champ ou endpoint modifié | diff `1436bae..2e87c53` | Conforme | Le diff ne touche que les 8 fichiers attendus. `SupabaseService.swift` non modifié. Seule la valeur `source` change, et seulement sur la branche `.confirm` (`LocationUpdateSheet.swift:321`). |
| 3 | Déplacement si seuil < écart ≤ 100 m, présence ≤ 50 m, précision ≤ 50 m | `BookBox.swift:243-247`, `LocationUpdateSheet.swift:68-72` | Conforme | Ordre des gardes : pas de position, puis `tooFar`, puis `badAccuracy`, puis `moveTooFar`, puis le seuil. Test : écart 100 → move ; 100.001 → moveTooFar. |
| 3 | Au-delà de 100 m : grisé et message | `LocationUpdateSheet.swift:239-241` (message), `:70` (`canSubmit` faux), `:267, 272` (fond gris et `.disabled`) | Conforme | Message « Tu ne peux pas déplacer la boîte de plus de 100 m. » présent, mot pour mot. |
| 4 | Libellé `.confirm` / `.move` | `LocationUpdateSheet.swift:261` | Conforme | `kind == .move ? "Envoyer le nouvel emplacement" : "Oui, elle est bien ici"`. |
| 4 | Ligne grise sous le seuil | `LocationUpdateSheet.swift:242-246` | Conforme | `isConfirm` et `d ≥ 1` : « Écart de X m : dans la marge du GPS (moins de Y m), la boîte reste à sa place. ». Voir remarque R1 sur l'arrondi de Y. |
| 5 | Message orange « Précision entre 10 et 50 m » retiré | `LocationUpdateSheet.swift:119-121` | Conforme | Le `else if` a disparu. Seul reste le message « plus de 50 m ». |
| 5 | Texte d'attente GPS sans 10 m | `LocationUpdateSheet.swift:195-199` | Conforme | « Patiente, le GPS affine ta position… ». |
| 5 | Message `ProximityAlertService` | `Services/ProximityAlertService.swift:187` | Conforme | « précision de 50 m au plus ». |
| 5 | Pas de texte utilisateur contradictoire dans les fichiers modifiés | grep « 10 m » | Conforme, avec remarques | Il reste des commentaires (`BookBox.swift:213`, voir R2). Aucun libellé affiché ne dit 10 m pour la confirmation. |
| 6 | Build 20 | `project.yml:25`, `BoitesALivresNative.xcodeproj/project.pbxproj:357` et `:440`, `CHANGELOG.md:14-18`, `release-notes/fr-FR.txt:1`, `release-notes/en-US.txt:1` | Conforme | `CURRENT_PROJECT_VERSION` 19 → 20 aux deux configurations. Aucun `= 19` restant. Dans les notes, seule la ligne « build 19 » a changé. |

## Points prioritaires

- **Aucun envoi refusé par le serveur** : prouvé. Les deux chemins d'envoi sont gardés par `canSubmit` (`LocationUpdateSheet.swift:307`), qui exige `acc ∈ [0,50]`. `source` vaut `gps` seulement si `acc ≤ 10` (`BookBox.swift:263`).
- **Chemin `blocked`** : `canSubmit` renvoie faux (`LocationUpdateSheet.swift:70`), le bouton est `.disabled` (`:272`), et `submit()` s'arrête (`:307`).
- **Cas limites** (vérifiés par exécution, `swiftc` sur `Models/BookBox.swift`) : acc -1 bloque ; écart exactement 20 (acc 5) = confirm ; 20.001 = move ; écart exactement 100 = move ; 100.001 = moveTooFar ; présence exactement 50 = autorisée ; 50.0001 = tooFar ; précision exactement 50 = autorisée ; 50.0001 = bloquée ; précision exactement 10 = gps ; 10.0001 = manual ; précision 0 = gps.
- **Régression submit** : `kind`, `lat`/`lng`, `address`, `city`, `postalCode`, `department`, `accuracyM` et `device_token` sont inchangés. Seule la `source` de la branche `.confirm` change, et elle devient `manual` au-delà de 10 m.

## Vérifications exécutées

- Test existant `scratchpad/t/main.swift` compilé avec `Models/BookBox.swift` : `RESULTAT: VERT (0 échec)`.
- Test complémentaire aux bornes exactes (18 cas) : `EXTRA VERT`.
- `swiftc -parse Views/Components/LocationUpdateSheet.swift` : sans erreur. Pas de compilation complète (dépendances `LocationService`, `SupabaseService`, etc. hors périmètre).

## Réserves (prouvées)

Aucune.

## Remarques (issue)

- **R1, arrondi de Y** : `Views/Components/LocationUpdateSheet.swift:244-245` affiche `Int(threshold.rounded())`. Avec acc 10.2, le seuil vaut 20.4 et s'affiche « moins de 20 m ». Un écart de 20.2 m reste en `.confirm`, donc le texte est faux de 0,2 m. Cosmétique.
- **R2, commentaire périmé** : `Models/BookBox.swift:213` dit « Envoi possible seulement avec 10 m de précision ou mieux », alors que `canSend` ne sert plus qu'à choisir `source`.
- **R3, libellé** : `LocationUpdateSheet.swift:211` dit « envoie », mais le bouton dit « Oui, elle est bien ici ».
- **R4, fraîcheur** : `LocationUpdateSheet.swift:36` lit `locationService.currentLocation` sans contrôle de fraîcheur (le `isFresh` existe seulement dans `AddBoxViewModel`). La confirmation passe maintenant de 10 m à 50 m de précision, donc une position en cache est acceptée plus souvent. Déjà signalé par R033 pour la présence. Hors périmètre de ce diff.
- **R5, pré-existant** : `canSubmit` exige `phase == .editing` (`:69`). Après un `.failed`, le bouton reste grisé, alors que le message dit « Réessaie ». Déjà présent avant ce commit.
- **R6, migration** : la contrainte `[0,50]` pour `manual` vient d'une migration de l'autre dépôt (`BoitesALivres/supabase/migrations/20261019180000_...`). Je n'ai pas vérifié son application en production. Le vault indique que l'envoi à 10-50 m dépend de cette migration.
