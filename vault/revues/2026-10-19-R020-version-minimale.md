---
verdict: RÉSERVE
tip: 54b868fa29a9761cdcf384ee7f79486a0cd19bb0
niveau: N3
---

# R020 -- Doublage indépendant : version minimale (M0025)

Périmètre : `git diff 41488d1 54b868f` (base `origin/main`), 8 fichiers, 152 insertions, 3 suppressions.
Relecture par sous-agent frais, lecture seule (`git show`). Citations recontrôlées par la session mère
contre le tip `54b868f` (lignes ±1 près).

## Verdict

**RÉSERVE, non levée.** Pas de merge sur `main` tant que la réserve (a) n'est pas tranchée.

## Constats

**(a) Écran bloquant : RÉSERVE.** L'écran est un `.overlay` posé sur `ContentView`
(`BoitesALivresNative/App/BoitesALivresApp.swift:27-28`). Des présentations SwiftUI (`.sheet`,
`.fullScreenCover`) sont ouvertes depuis les descendants : `App/MapScreen.swift:173,176`,
`App/ListView.swift:90,104`, `App/AddBoxView.swift:32`. Une présentation passe au-dessus d'un overlay
de sa vue parente. Cas qui échoue : une modale est ouverte, l'app passe en arrière-plan, `min_version`
monte, puis retour au premier plan : l'écran bloquant est sous la modale. Preuve par lecture de code et
de la hiérarchie de présentation, **non exécutée** (pas de test d'interface dans le dépôt).

**(b) Lecture en échec : OK.** Le `catch` ne fait que journaliser (`Services/AppVersionGate.swift:25-27`) ;
`mustUpdate` n'est pas modifié.

**(c) Valeur illisible : écart mineur.** `AppVersion.isBelow` renvoie `false` pour une valeur illisible
(`Services/AppVersion.swift`, `isBelow`), donc `mustUpdate = false` (`AppVersionGate.swift:24`). Le
comportement voulu (ne jamais bloquer) est respecté, mais le cas n'est pas journalisé comme demandé
(« journaliser et continuer »).

**(d) Comparaison numérique : OK.** `AppVersion.swift` (parse, isBelow) : 1.10.0 > 1.9.9, « 1.3 » = « 1.3.0 »,
segments manquants à 0. Aucun cas de blocage à tort trouvé.

**(e) Aucune écriture en base : OK.** La seule requête `app_config` est un GET
(`Services/SupabaseService.swift:101-112`, `makeRequest` par défaut).

**(f) Déclencheurs : OK.** Lancement (`BoitesALivresApp.swift`, `.task`) et `scenePhase == .active`
(`.onChange`).

**(g) Concurrence : OK.** `AppVersionGate` est `@MainActor @Observable` ; `SupabaseService` est un `actor` ;
`await` présent. Deux `check()` qui se chevauchent peuvent finir dans le désordre (cas théorique).

**(h) Version et projet : OK.** `CURRENT_PROJECT_VERSION = 16` aux deux occurrences du `pbxproj`, aucune à 15 ;
`project.yml` à 16 ; `MARKETING_VERSION` 1.3.0 ; CHANGELOG « Build 16 » ; les 3 nouveaux fichiers sont inscrits
(référence, build file, groupe, phase Sources). `plutil -lint` OK.

**(i) Écran, texte, lien : OK.** `Views/Components/ForceUpdateView.swift` (titre, texte, bouton) ;
lien `https://apps.apple.com/app/id6768351762` (`AppVersionGate.swift`, `appStoreURL`). Pas de bouton de fermeture.

## Vérifications de la session mère

- Build Release `generic/platform=iOS`, CODE_SIGNING_ALLOWED=NO : `** BUILD SUCCEEDED **`.
- Tests de logique pure (hors dépôt, `swiftc`) : 20/20 cas OK (mandat + cas limites hostiles).
- Lecture réelle `app_config` (SELECT seul) : `[{"min_version":"1.3.0","current_version":"1.3.0"}]`, HTTP 200.
- Budget : `sh scripts/harnais-hooks/pre-commit --controle 54b868f… --base 41488d1…` → 4 OK, 0 ATTENTION, 0 BLOQUE, rc=0.

## Non testé

- Rendu et captures de l'écran sur appareil ou simulateur.
- Comportement réel d'une modale ouverte pendant le blocage (point a).
- Réseau : hors ligne, délai, réponse lente, chevauchement de deux `check()`.
- Retour de `min_version` sous la version de l'app pendant le blocage (écran qui disparaît).
- Politique RLS de `app_config` côté Supabase (la lecture anon réussit ; l'écriture anon n'a pas été testée, volontairement).

## Décision à prendre (fondateur)

Option A (recommandée) : porter l'écran dans une fenêtre UIKit dédiée, au-dessus des modales, pilotée par `AppVersionGate`.
Couvre le cas (a). Coût : gestion de la scène, à vérifier sur appareil.

Option B : présenter l'écran depuis la racine via `.fullScreenCover`. Ne couvre pas une modale déjà ouverte : défaut partiel.

Option C : accepter la limite et la consigner (une modale ouverte reste utilisable jusqu'à sa fermeture).
Le point (c) se corrige dans tous les cas par un journal.
