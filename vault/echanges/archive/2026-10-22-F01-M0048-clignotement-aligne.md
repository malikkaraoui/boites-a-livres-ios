---
date: 2026-10-22
tags: [clignotement, alignement, ui, build-25]
session: F01
mandat: clignotement-aligne-sur-l-element
mandat_id: M0048
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0048
branche: feat/carte-localisation
niveau: N3
derniere_maj: 2026-10-22T22:10:07+0200
---

# F01 / M0048 — Cadre qui clignote aligné exactement sur l'élément (tous les écrans) ; build 25

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Un STOP propre est un rendu valable. Demande d'autorisation d'outil : contourne ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (doublage compris). **N3** (`project.yml`/`project.pbxproj`).

## Retour terrain du fondateur (22/10/2026 22:09, build 24, « Donner mon avis », trop loin), verbatim
« le rectangle qui clignote pour me rappeler que je suis trop loin n'est pas correctement centré sur le texte dessous ». Capture : le cadre orange déborde à gauche/droite et en bas du bandeau « Trop loin pour noter… ». « pas besoin de migration, rien besoin de changer sur la base de donnée ».

## Cause (lue par l'orchestrateur sur `d2fc9eb`)
`Views/Components/ReviewSubmitSheet.swift:148-150` : `proximityBanner.missingHighlight(tick:…)` est appliqué APRÈS les marges extérieures du bandeau (`.padding(.horizontal, 20)` et `.padding(.bottom, 14)`, ~l.280-284) : le cadre (`MissingHighlight`, `Views/Components/ButtonStyles.swift` ~l.57) entoure la marge, pas le bandeau, et son rayon (12 par défaut) peut différer de celui de l'élément.

## Règle
1. Le cadre/fond qui clignote épouse **exactement** la forme visible de l'élément : appliqué après le fond et la découpe de l'élément, **avant** ses marges extérieures, avec le **même rayon d'angle** que l'élément.
2. Vérifie et corrige **chaque** appel de `missingHighlight` (aujourd'hui : `App/AddBoxView.swift:225`, `:292` ; `Views/Components/DeletionRequestSheet.swift:68` ; `Views/Components/LocationUpdateSheet.swift:124`, `:135`, `:249` ; `Views/Components/ReviewSubmitSheet.swift:150`, `:319`, `:400`). Pour chacun, au rapport : aligné avant / corrigé / rayon utilisé.
3. Si plus simple et sûr : laisser `missingHighlight` sans changement et déplacer les marges extérieures hors des vues ciblées ; ou ajouter au modificateur un paramètre d'inset. Une seule approche, la même partout.
4. Rien d'autre ne change (comportement M0045/M0047, textes, envoi). **Aucun changement de payload, d'endpoint, de base.**

## Version 25
`project.yml` `CURRENT_PROJECT_VERSION: 25`, `project.pbxproj` aligné, `CHANGELOG.md` « Build 25 » ; `release-notes/fr-FR.txt` et `en-US.txt` : seulement « build 24 » → « build 25 » (`grep -nE '^[[:space:]]*([-•*·.]|[0-9]+\.)'` vide, collé).

## Interdits permanents
**Aucun geste git en écriture à la racine** (seuls `git fetch origin`, `git worktree add/remove/prune` et lectures). **Pas de merge vers `main`.** Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase. `git add` ciblé. **Aucune écriture Supabase, aucune migration, aucun changement de payload.** **Aucun appel à Apple.** Commits en heredoc terminés par `Co-Authored-By: Malik & Claude` (pas d'autre trailer). Rapports de revue **sous `vault/revues/` à la racine du dépôt**.

## Garde (écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/feat/carte-localisation` = `d2fc9eb86f690f8d9044e52e6d048be8242b0c52`.
2. `.claude/worktrees/F01-M0048` absent ; aucun autre worktree sur `feat/carte-localisation`.

## Mise en place
`git worktree add .claude/worktrees/F01-M0048 feat/carte-localisation` ; dans le worktree `git merge --ff-only origin/feat/carte-localisation` ; `git rev-parse HEAD` = `d2fc9eb…` collé (sinon STOP).

## Travail
1. Issue `gh issue create` « Cadre qui clignote mal aligné » avec le retour verbatim ; numéro cité dans les commits. Ne la ferme pas.
2. Applique la règle ; version 25.
3. **Tests** : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (fin collée) ; `node --test scripts/release/asc.test.mjs` vert. **Preuve d'écran** : captures simulateur (avis trop loin avec le cadre allumé — `reduceMotion` ou état forcé si besoin, sans changer le code livré) dans `vault/revues/captures-M0048/` ; impossible → le dire, checklist fondateur.
4. Commits ciblés, push + `git ls-remote` collé. Tip de code = `T`.
5. **Doublage N3 `R040`** (relu dans `state.json` ; s'il diffère, prends sa valeur et dis-le) sur `d2fc9eb86f690f8d9044e52e6d048be8242b0c52..T` : sous-agent FRAIS (Haiku), worktree détaché lecture seule sur `T`. Vérifie fichier:ligne chaque appel (ordre modificateur/marges, rayon), rien d'autre de changé, build 25 cohérent, budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base d2fc9eb86f690f8d9044e52e6d048be8242b0c52` collé. Rapport `vault/revues/2026-10-22-R040-clignotement-aligne.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N3`. Réserve prouvée par test rouge → un correctif + re-doublage en chaîne ; 2e réserve de même classe → STOP. Remarques → issues. Rapport committé + push + `ls-remote` collé.
6. **Si GO : installation sur l'iPhone de Malik** (Wi-Fi) depuis un worktree détaché sur le tip GO : `xcrun devicectl list devices` collé ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` signature automatique `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E …` ; lancement (verrouillé = le dire) ; **`device info apps` collé tel quel** → `1.3.0 25`. `unavailable` ou verrouillé → le dire.
7. Retire tous les worktrees du mandat.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'écrit en base ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0048` dans ce fichier (5 lignes max en français simple ; appels vérifiés ; preuves ; gestes de test terrain) → `vault/runtime/events.jsonl` + `state.json` (jamais committés ; `next_revue_id` avancé) → aucun commit à la racine → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, première ligne `M0048` ; Merge main / Main push = ❌ volontaire ; TASK STATUS `READY_FOR_INTEGRATION` si GO et poussé, sinon `BLOCKED` ; PROJECT STATUS `NOT_INTEGRATED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0048

Le cadre orange qui clignote épouse maintenant la forme visible de l'élément : trois marges extérieures ont été déplacées hors du cadre. Build 25 installé sur l'iPhone de Malik (`1.3.0 25`). Preuve d'écran simulateur non faite : checklist ci-dessous. Issue #57 ouverte, non fermée.

Appels `missingHighlight` vérifiés (R040, fichier:ligne sur `a52d949`) :

| fichier:ligne | avant | après | rayon |
|---|---|---|---|
| App/AddBoxView.swift:225 | aligné (inchangé) | aligné | 14 / 14 |
| App/AddBoxView.swift:290 | marge H 16 dans le cadre → corrigé | aligné | 8 / aucune forme |
| Views/Components/DeletionRequestSheet.swift:66 | marge H 20 dans le cadre → corrigé | aligné | 12 / 12 |
| Views/Components/ReviewSubmitSheet.swift:150 | marges 20 H + 14 B dans le cadre → corrigé | aligné | 12 / 12 |
| Views/Components/ReviewSubmitSheet.swift:319 | aligné (inchangé) | aligné | 12 / 12 |
| Views/Components/ReviewSubmitSheet.swift:400 | aligné (inchangé) | aligné | 12 / 12 |
| Views/Components/LocationUpdateSheet.swift:124, :135, :249 | aligné (inchangé, texte nu) | aligné | 8 / aucune forme |

Preuves : `BUILD SUCCEEDED` Release (deux passes, dont la dernière sur `a52d949`) ; `asc.test.mjs` 17/17 ; `git ls-remote` = `35a7baa` ; `devicectl device info apps` = `Boîtes à Livres 1.3.0 25`.

Gestes de test terrain (fondateur, sur l'iPhone, build 25) :
1. « Donner mon avis », boîte à plus de 100 m : le cadre entoure exactement le bandeau « Trop loin… », sans débord à gauche, à droite ni en bas.
2. « Demande de suppression », envoi sans raison : le cadre entoure le champ Motif, sans marge.
3. « Ajout de boîte », bouton grisé : le cadre entoure le message, sans débord.
4. Réglage « Réduire les animations » : surlignage fixe, même forme.

Footer :

```
M0048
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌ (volontaire, pas de merge vers main dans ce mandat)
Main push           ❌ (volontaire)
TASK STATUS         READY_FOR_INTEGRATION
PROJECT STATUS      NOT_INTEGRATED
```

Constat hors périmètre (non corrigé) : `git status` à la racine montre des modifications non committées venues d'une autre session (`.claude/skills/orchestration-bureau/…`, `config/harnais.json`, `scripts/harnais-hooks/…`). Signalé au relecteur, non touché.
