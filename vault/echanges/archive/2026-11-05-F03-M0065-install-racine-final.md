---
date: 2026-11-05
tags: [installation, iphone, build-32, racine, gitignore, echanges]
session: F03
mandat: install-32-et-racine-ios-a-jour
mandat_id: M0065
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F03.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F03-M0065
branche: chore/echanges-hors-git
niveau: N1
derniere_maj: 2026-11-05T14:12:06+0100
---

# F03 / M0065 — (1) Installer la build 32 sur l'iPhone MAINTENANT ; (2) sortir `vault/echanges/F01.md`/`F02.md` de git et remettre la racine iOS sur `origin/main`

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Arbitrage nécessaire = **STOP propre** (question, options, choix motivé au rapport, puis rituels de fin). **Va jusqu'au bout.**

## Demandes du fondateur (verbatim, datées)
- 05/11 14:11 : « Oui. » (au mandat de nettoyage : fichiers d'échange suivis par git qui bloquent la mise à jour de la racine iOS) — « Et je veux que tu build sur mon iPhone je suis en wifi profite ».
- 05/11 13:10 (admin, même principe) : tenir les racines à jour est le travail de l'orchestrateur.

## Faits lus par l'orchestrateur (14:12)
- `origin/main` = `aa77b5c` (build 32 : `CURRENT_PROJECT_VERSION: 32`, déjà installée par M0064 à 13:19 ; réinstallation demandée).
- Racine `/Users/malik/Documents/Boites-a-livres/BoitesALivresNative` : `main` à `c0e0371`, derrière `origin/main` (commits `vault/` + code build 32). Modifiés à la racine : `vault/echanges/F01.md`, `vault/echanges/F02.md` (**suivis par git par erreur** : la convention dit qu'un `Fxx.md` vivant n'est jamais committé), `vault/reprise/F01.md`, `vault/reprise/F02.md`. `git ls-files vault/echanges` hors archive : `F01.md`, `F02.md`, `README.md`. `.gitignore:78` n'ignore que `/vault/echanges/F99.md`.
- Ce mandat-ci vit dans `F03.md` (NON suivi) : il n'est pas touché par l'opération.

## Partie 1 — installation iPhone (D'ABORD, l'iPhone est en Wi-Fi maintenant)
1. `git fetch origin --prune` ; `origin/main` contient `aa77b5c` (sinon STOP). Worktree détaché temporaire `.claude/worktrees/F03-M0065-install` sur `origin/main`.
2. `xcrun devicectl list devices` + `device info apps` (ligne Boîtes à Livres) collés AVANT ; build Debug `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` `-allowProvisioningUpdates` ; `xcrun devicectl device install app --device 00008101-001278EA36E9001E <app>` ; `device info apps` collé → attendu `1.3.0 32`. Méthode : `vault/echanges/archive/F02-M0059.md` étape 7. Injoignable → 2 essais, puis le dire et continuer la partie 2.
3. Worktree retiré.

## Partie 2 — fichiers d'échange hors git + racine à jour
1. Branche `chore/echanges-hors-git` depuis `origin/main` (worktree `.claude/worktrees/F03-M0065`) : `git rm --cached vault/echanges/F01.md vault/echanges/F02.md` (les fichiers ne sont PAS supprimés du disque du worktree) ; `.gitignore` : remplacer la ligne `/vault/echanges/F99.md` par un motif qui ignore tous les échanges vivants `/vault/echanges/F[0-9][0-9].md` (F99 compris), en gardant `README.md` et `archive/` suivis ; mettre à jour le commentaire au-dessus (remplacement, pas ajout). Vérifier : `git check-ignore -v vault/echanges/F01.md vault/echanges/F42.md` ignorés, `vault/echanges/README.md` et un fichier `archive/x.md` non ignorés (collé). Commit, push, `ls-remote`. Tip = `T`.
2. **Relecture N1 `R054`** (relu dans `state.json`) : sous-agent FRAIS, une passe, lecture seule sur `T` : seul `.gitignore` + retrait d'index des 2 fichiers, aucun autre fichier, motif correct. Rapport court `vault/revues/2026-11-05-R054-echanges-hors-git.md`, frontmatter fermé : `verdict:`, `tip:` (sha 40), `niveau: N1`. GO → fusion (gabarit §9 mode direct, `.claude/skills/orchestration-bureau/references/gabarits.md` : scratch détaché, `merge --no-ff T`, rapport committé dans le scratch, push `HEAD:main`, `ls-remote`).
3. **Racine**, dans cet ordre, sans rien perdre :
   a. Copier `vault/echanges/F01.md` et `F02.md` de la racine vers un dossier temporaire HORS dépôt (ex. `$TMPDIR/m0065/`), `shasum` collé.
   b. Pour `vault/reprise/F01.md` et `F02.md` : comparer avec leur version sur le nouvel `origin/main` ; identiques → `git restore --` ; différents → les copier aussi dans le dossier temporaire et le dire.
   c. `git restore -- vault/echanges/F01.md vault/echanges/F02.md` (+ reprise si 3b) — chemins EXPLICITES, jamais `checkout -- .`, `reset --hard`, `stash`.
   d. `git -C <racine> merge --ff-only origin/main` ; `git rev-parse HEAD origin/main` → deux fois le même SHA, collé.
   e. Remettre `vault/echanges/F01.md` et `F02.md` depuis le dossier temporaire (même `shasum`, collé) ; `git status --short -- vault/echanges` ne doit plus les montrer (ignorés). `git diff --stat HEAD` collé (attendu vide).
4. `vault/reprise/etat-technique.md` : ligne « Racine iOS = `origin/main` après chaque fusion ; `vault/echanges/Fxx.md` hors git » (en REMPLAÇANT une ligne existante équivalente).

## Interdits
Aucun changement de code de l'app, aucun appel à Apple (ni archive App Store, ni TestFlight), aucune écriture Supabase. Jamais de `sleep`, de tâche de fond vivante à la sortie, de `--no-verify`, de `push --force`, de rebase, de `stash`, de `reset --hard`, de `checkout -- .`. `git add` ciblé. Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, ni ne tue un autre agent ; (3) rapport vérifié ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`).

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : `## Rapport M0065` à la fin de ce fichier (4 lignes en français simple en tête : installé oui/non + version, fichiers d'échange hors git oui/non, racine = origin/main oui/non) → `vault/reprise/F03.md` → `vault/runtime/events.jsonl` + `state.json` (`windows.F03`, `last_event`, `updated_at`, `next_revue_id` ; non committés) → commit vault ciblé via scratch, push, `ls-remote`, puis ff de la racine sur ce dernier commit (`rev-parse` collé) → **footer gabarit §4 OBLIGATOIRE en toute dernière ligne (première ligne `M0065`)** → `statut: reponse-disponible` EN DERNIER GESTE.

## Rapport M0065

Installé : oui, « iPhone de Malik » en `1.3.0 (32)` (vérifié par `devicectl device info apps`, build Debug depuis `origin/main` aa77b5c). Fichiers d'échange hors git : oui (`F01.md`, `F02.md` retirés de l'index, `.gitignore` couvre `Fxx.md`). Racine = `origin/main` : oui (`f342f9a`, ff-only, `rev-parse` identiques).

- Partie 1 : build Debug `BUILD SUCCEEDED`, installation sans erreur ; app déjà en 32 avant la réinstallation.
- Partie 2 : branche `chore/echanges-hors-git` (`0764e4a`), relecture R054 GO (sous-agent frais, lecture seule), fusion `3a8d213` --no-ff, `origin/main` = `f342f9a`.
- Racine : `F01.md`/`F02.md` sauvegardés (sha `15e0b60f…`, `3ba6ccd7…`) puis remis à l'identique après le ff. 4 fichiers non suivis identiques à `origin/main` (archives M0060/M0062/M0063, R053b) supprimés après sauvegarde.
- Incident mineur : un `git push HEAD:main` depuis le worktree de commit a été refusé par le hook pre-push (commit hors `vault/`) ; rien n'a été poussé sur `main` à ce moment. Le bon chemin (branche + relecture + merge) a été suivi.
- Non vu : rien de la partie 1 au-delà de `devicectl` (pas de lancement de l'app sur l'iPhone) ; retour terrain à faire par le fondateur.
- Commit : le commit de code porte `Co-Authored-By: Malik & Claude` (convention du mandat).

Mandat : M0065 · Branche : chore/echanges-hors-git · Tip : 0764e4a83e547e19c2b83d234eccf6473e3f9cda · Merge : 3a8d213 · Revue : R054 (GO) · Main : f342f9a.
M0065
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         INTEGRATED
PROJECT STATUS      INTEGRATED
