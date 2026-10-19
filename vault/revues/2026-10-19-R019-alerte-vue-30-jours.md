---
verdict: GO
tip: 70af1ac256a90130ccea9603ae9793aff2291609
niveau: N3
---

# R019 -- Doublage indépendant : alerte affichée = vue (30 j)

Périmètre : `git diff 95051e1 HEAD` (base `origin/main`), 4 fichiers, 12 insertions, 4 suppressions. Lecture seule, aucune écriture hors de ce rapport.

## Périmètre du diff (f)

```
 BoitesALivresNative.xcodeproj/project.pbxproj            | 4 ++--
 BoitesALivresNative/Services/ProximityAlertService.swift | 5 ++++-
 CHANGELOG.md                                             | 5 +++++
 project.yml                                              | 2 +-
```

Aucun autre fichier modifié. `BoitesALivresNative/Models/BookBox.swift` et `App/AppDelegate.swift` ne sont pas touchés par le diff.

## Constats vérifiés

**(a) Ordre dans `notifyIfAllowed` : OK.** `ProximityAlertService.swift`
- l.87-88 : garde `handledInside`, insertion.
- l.89-93 : contrôle `blocked` ; si bloqué, journal « bloquée » et retour.
- l.94 : journal « notification envoyée ».
- l.95 : `LocationPromptLog.mark(boxId: boxId)`.
- l.96 : journal « anti-répétition posée : boîte N, 30 j ».
- l.97 : `scheduleNotification(boxId:)`.
La pose est bien après le contrôle `blocked` et avant `scheduleNotification`.

**(b) Symptôme corrigé : OK.** La pose (l.95) a lieu à l'envoi, sans attendre de réponse. Une notification ignorée (ni « Plus tard », ni toucher) pose donc la date. Avant le correctif, la seule pose hors contrôle était `AppDelegate.swift:53-55` (« Plus tard »), qui est inchangé.

**(c) Exclusion dans `regionCandidates` : OK.** `Models/BookBox.swift:222-227`, filtre `.filter { !isBlocked(lastPrompt: prompts[$0.id], now: now) }` (l.226), appliqué avant le tri par distance et le `prefix(limit)`. `ProximityAlertService.swift:59-61` passe `LocationPromptLog.all()` et `Date()`. La boîte posée sort des régions au prochain `refreshRegions`, déclenché par `start()` (l.36) ou `didUpdateLocations` (l.128), comme attendu.

**(d) Fenêtre : OK.** `BookBox.swift:185` `repeatWindowSeconds: TimeInterval = 30 * 86_400`. `BookBox.swift:216-219` `isBlocked` retourne `now.timeIntervalSince(last) < repeatWindowSeconds` (comparaison stricte). Le harnais confirme : +29 j bloquée, +30 j exact éligible, +31 j éligible.

**(e) Version : OK.** `grep -n "CURRENT_PROJECT_VERSION = 14" project.pbxproj` : aucune occurrence (rc=1). Les deux configurations passent à `= 15` (`project.pbxproj:345` et `:428`). `project.yml:25` = 15. `MARKETING_VERSION` reste 1.3.0 (`project.yml:24`). `Info.plist:20` lit `$(CURRENT_PROJECT_VERSION)`. CHANGELOG : section « Build 15 » (ligne 14-18).

**Régression « Plus tard » et toucher de la notification : aucune.** `AppDelegate.swift:53-55` (« Plus tard » pose la date) et `:56-61` (toucher : `pendingLocationBoxId` et `pendingBoxId`, ouverture de la fiche) sont inchangés. Le toucher n'appelle jamais `isBlocked`, donc la fiche reste accessible même pour une boîte bloquée. Les seuls appelants de `isBlocked` sont `ProximityAlertService.swift:89` et `BookBox.swift:226`.

**Effets de bord sur `handledInside` : aucun.** Le correctif n'y touche pas (`ProximityAlertService.swift:21`, `:71`, `:88`, `:138-140`). Après une pose, la boîte reste dans `handledInside` pendant la présence (inchangé). Une re-entrée après sortie passe par `isBlocked` et journalise « bloquée » sans notifier.

**Point à noter (remarque, pas réserve) : la pose précède l'acceptation système.** `ProximityAlertService.swift:95` pose la date avant `scheduleNotification` (l.113-121). Or `:121` appelle `UNUserNotificationCenter.current().add(request)` sans gestionnaire d'erreur : si iOS refuse la requête (notifications refusées, cf. `Services/NotificationService.swift:11-18` et `BoitesALivresApp.swift:29`), la boîte est bloquée 30 jours sans qu'aucune alerte ne soit affichée. Ce cas est strictement conforme à l'attendu du mandat (« pose au moment de l'envoi, avant scheduleNotification »), donc ce n'est pas une réserve. Mais la décision du fondateur dit « une alerte affichée », pas « une alerte envoyée ». Suggestion pour une issue de suivi, hors de ce correctif : vérifier `notificationSettings().authorizationStatus` avant la pose, ou poser dans le gestionnaire de `add` en cas de succès. Cela ne bloque pas la livraison.

**Fiche depuis la notification : OK** (voir plus haut, `AppDelegate.swift:56-61`).

## Harnais de logique pure (2)

Lancé tel quel : `/private/tmp/claude-501/-Users-malik-Documents-Boites-a-livres-BoitesALivresNative/fe6dc333-c485-4f86-a31f-ea0642457af9/scratchpad/m0024/test-alerte`

```
OK   avant envoi : boîte 7 non bloquée
OK   date persistée (round-trip UserDefaults)
OK   à l'envoi : boîte 7 bloquée
OK   +29 j : toujours bloquée
OK   +31 j : de nouveau éligible
OK   +30 j exact : éligible (fenêtre stricte <)
OK   +1 j : boîte bloquée absente des régions
OK   +1 j : les autres boîtes restent, triées par distance ([8, 9])
OK   +31 j : boîte 7 de nouveau sélectionnable
OK   plafond : 20 régions (20)
OK   plafond : 2 boîtes bloquées les plus proches exclues
OK   plafond : la plus proche non bloquée est en tête (103)
OK   journal corrompu : entrée non numérique ignorée
RÉSULTAT : tout vert
```
rc=0 (13 OK, 0 FAIL). Le harnais n'est pas recompilé : `BookBox.swift` est absent du diff, donc identique à la base.

## Budget (3)

Commande : `cd <worktree> && sh "$(git config core.hooksPath)/pre-commit" --controle 70af1ac256a90130ccea9603ae9793aff2291609 --base 95051e1ec23d91093bf67768de42cb7d58153cf7`

```
OK        .claude/skills/orchestration-bureau/SKILL.md : 28992 caracteres (seuil 40000), ligne la plus large 399 (seuil 400)
OK        CLAUDE.md : 45 caracteres (seuil 40000), ligne la plus large 44 (seuil 400)
OK        vault/reprise/00_INDEX.md : 1973 caracteres (seuil 80000), ligne la plus large 107 (seuil 400)
OK        vault/reprise/CARNET_DE_BORD.md : 1149 caracteres (seuil 40000), ligne la plus large 94 (seuil 400)
controle-instructions : 4 fichier(s) charge(s) d'office dans 70af1ac256a90130ccea9603ae9793aff2291609 (base 95051e1ec23d91093bf67768de42cb7d58153cf7) -- 4 OK, 0 ATTENTION, 0 BLOQUE
rc=0
```

## Ce que je n'ai PAS pu vérifier

- `scheduleNotification` et la requête `UNUserNotificationCenter` ne sont pas exécutés. La pose à l'envoi est vérifiée par lecture seule (`ProximityAlertService.swift:85-98`), pas par test.
- Aucune compilation Xcode / `xcodebuild` ni test sur appareil : le code de `ProximityAlertService.swift` (dépendances `LocalCacheService`, `DeepLinkRouter`, `UNUserNotificationCenter`) n'a pas été typé. Seule la logique `LocationRules` / `LocationPromptLog` du vrai `BookBox.swift` est exercée.
- Le comportement réel d'iOS quand `add(request)` échoue (notifications refusées) n'est pas testé ; le constat ci-dessus repose sur la lecture du code.
- Pas de vérification que le journal « anti-répétition posée » apparaît dans l'écran « Diagnostic des alertes » (`ProximityDiagnosticView`) : non lu.
- Remarque hors périmètre, non corrigée ici : `CHANGELOG.md` garde l'en-tête « Build 13. Contenu depuis la 1.2.0... » sous `[1.3.0]`, alors que les builds 14 et 15 existent. Déjà présent avant ce correctif.

## Verdict

**GO.** Aucune réserve prouvée : les points (a) à (f), la non-régression de « Plus tard » et du toucher, et le budget sont vérifiés par lecture et par exécution. La remarque sur l'échec silencieux de `add` est à traiter en issue de suivi.
