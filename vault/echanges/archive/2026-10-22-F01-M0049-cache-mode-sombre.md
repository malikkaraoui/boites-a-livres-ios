---
date: 2026-10-22
tags: [reglages, cache, mode-sombre, avis, build-26]
session: F01
mandat: retrait-vider-cache-et-mode-sombre
mandat_id: M0049
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0049
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-22T22:25:02+0200
---

# F01 / M0049 — Retirer « Vider le cache » des Réglages ; mode sombre : cellules des formulaires visibles comme en clair ; build 26

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3** (`ViewModels/SettingsViewModel.swift`, `project.yml`/`project.pbxproj`).

## Décisions / retours du fondateur (22/10/2026 22:19, build 25), verbatim
« Supprimer vider le cache dans réglages ».
« En mode sombre la page avis n'est pas affichée correctement. Les encadrements (cellules) encadrant le nombre de livres et le nom ne s'affichent pas comme la version claire. »
Captures : en clair, « Nombre estimé de livres » et « Votre nom » sont dans des cellules arrondies gris clair ; en sombre, ces fonds disparaissent (le stepper et le champ nom flottent sur le fond noir), alors que le commentaire, l'état et le bandeau gardent leur cadre.

## Travail A — Retirer « Vider le cache »
`App/SettingsView.swift` ~l.525-540 (bouton « Vider le cache » / « Cache vidé », alerte « Vider le cache ? ») et `ViewModels/SettingsViewModel.swift` (`showCacheClearAlert`, `cacheClearDone`, action ~l.40-50) : retirer le bouton, l'alerte et le code devenu mort ; retirer les chaînes `Vider le cache`, `Vider le cache ?`, `Cache vidé` et leur message dans `fr.lproj` / `en.lproj/Localizable.strings` si plus utilisées. Si une fonction de vidage du cache est appelée ailleurs (ex. au démarrage, après mise à jour), **elle reste** : seul le bouton disparaît. Le dire au rapport.

## Travail B — Mode sombre
1. Écran avis (`Views/Components/ReviewSubmitSheet.swift`) : les fonds de cellules du nombre de livres et du nom utilisent une couleur fixe ou une couleur qui se confond avec le fond en sombre. Les remplacer par des couleurs **adaptatives** du système (ex. `Color(.secondarySystemBackground)` / `Color(.tertiarySystemBackground)` selon le fond de la feuille), de sorte que le rendu sombre reproduise la structure du rendu clair (cellule visible, même rayon, même marge).
2. **Même contrôle sur tous les formulaires** (`DeletionRequestSheet`, `AddBoxView`, `LocationUpdateSheet`, écran de succès commun, Réglages) : toute couleur de fond/bordure fixe (`Color.white`, `Color(white:)`, `Color(red:…)` pour un fond de cellule, `.systemGray6` utilisé hors contexte) qui disparaît en sombre → couleur adaptative. Liste au rapport chaque remplacement (fichier:ligne avant/après). Ne change pas les couleurs de marque (vert, orange, rouge des états).
3. Aucun changement de mise en page en mode clair (rendu identique).

## Commun
- **Aucun changement de payload, d'endpoint, de base.** **Aucun appel à Apple.**
- Version 26 : `project.yml` `CURRENT_PROJECT_VERSION: 26`, `project.pbxproj` aligné, `CHANGELOG.md` « Build 26 » ; `release-notes/fr-FR.txt` et `en-US.txt` : seulement « build 25 » → « build 26 » (`grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucune migration.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude` (pas d'autre trailer). Rapports de revue **sous `vault/revues/` à la racine du dépôt**.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `35a7baa9adb35e02e5456f9334049107eb4cf444`.
2. `.claude/worktrees/F01-M0049` absent ; aucun autre worktree sur `feat/carte-localisation`.

## Mise en place
`git worktree add .claude/worktrees/F01-M0049 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `35a7baa…` collé (sinon STOP).

## Travail commun
1. Issue `gh issue create` « Retirer Vider le cache ; mode sombre des formulaires » avec les retours verbatim ; numéro cité dans les commits. Ne la ferme pas.
2. A + B ; version 26.
3. **Tests** : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert ; grep collé : plus de « Vider le cache » dans `BoitesALivresNative/`. **Preuve d'écran** : captures simulateur avis en clair ET en sombre (`xcrun simctl ui booted appearance dark`) dans `vault/revues/captures-M0049/` ; impossible → le dire, checklist fondateur.
4. Commits ciblés, push + `git ls-remote` collé. Tip de code = `T`.
5. **Doublage N3 `R041`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur `35a7baa9adb35e02e5456f9334049107eb4cf444..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie : bouton et alerte retirés sans casser les Réglages, vidage automatique éventuel conservé, couleurs adaptatives partout listées, rendu clair inchangé, aucun changement de payload, build 26 cohérent, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base 35a7baa9adb35e02e5456f9334049107eb4cf444` collé. Rapport `vault/revues/2026-10-22-R041-cache-mode-sombre.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé + push + `ls-remote` collé.
6. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E …` ; lancement (verrouillé = le dire) ; **`device info apps` collé tel quel** → `1.3.0 26`. `unavailable` ou verrouillé → le dire.
7. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0049` dans ce fichier (5 lignes max en français simple ; remplacements listés ; preuves ; gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0049` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0049

- Retiré « Vider le cache » (bouton, alerte, code mort, chaînes FR/EN) ; clear() des caches sans appelant, retiré aussi.
- Mode sombre : les champs des formulaires utilisent `Color.formField` (clair = inchangé, sombre = `tertiarySystemBackground`).
- Version 26 ; commits `c474e3c` et `c1cb1e7` poussés ; revue R041 GO (`88cae44`) ; issue #58 ouverte, non fermée.
- Preuves : build Release `BUILD SUCCEEDED` ; `node --test scripts/release/asc.test.mjs` = 17 pass / 0 fail ; `grep "Vider le cache"` vide ; `controle-instructions` = 4 OK / 0 ATTENTION / 0 BLOQUÉ ; `devicectl device info apps` = `Boîtes à Livres  com.malikkaraoui.boitesalivresapp  1.3.0  26`.
- ⚠️ Non vérifié à l'écran : aucune capture clair/sombre (simulateur éteint ; l'écran avis exige une boîte à moins de 100 m et des données réelles). Contraste à confirmer sur l'iPhone.

Remplacements (avant → après) :
- `Views/Components/ReviewSubmitSheet.swift:351,365,384` : `Color(.systemGray6)` → `Color.formField`
- `Views/Components/DeletionRequestSheet.swift:49` : `Color(.systemGray6)` → `Color.formField`
- `Views/Components/ButtonStyles.swift:100-106` : ajout de `Color.formField`
- Déjà adaptatifs, non modifiés : `AddBoxView.swift` (secondary/tertiarySystemBackground), `LocationUpdateSheet`, `SubmissionSuccessView`, `SettingsView`.
- Restes `systemGray6` hors périmètre (adaptatifs) : `BookBoxSheet`, `PhotoCarousel`, `DetailView`, `ListView`.

Gestes de test terrain (iPhone de Malik, build 26) :
1. Ouvrir Réglages : il n'y a plus de section « Vider le cache » entre « À propos » et « Version ».
2. Mode sombre (Réglages iOS › Affichage) : ouvrir une boîte à moins de 100 m, « Donner mon avis », activer « Nombre estimé de livres ». Les cellules (nombre, « Votre nom ») doivent avoir un fond gris visible, comme en clair.
3. Même mode sombre : « Demander la suppression » à moins de 100 m ; le champ « Motif » doit avoir un fond visible.
4. Mode clair : les mêmes écrans doivent être identiques à la build 25.

Décisions prises : `clear()` des deux caches retirés car plus appelés ; `AddBoxView` laissé tel quel car déjà adaptatif ; issue #58 non fermée.

Notes au fondateur : le trailer des commits suit ce mandat (`Co-Authored-By: Malik & Claude`), pas le rappel de session Haiku ; aucun commit à la racine.

M0049
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌ (volontaire)
Main push           ❌ (volontaire)
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
