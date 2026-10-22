---
date: 2026-10-20
tags: [installation, iphone, build-16]
session: F01
mandat: installation-iphone-laura-et-malik
mandat_id: M0033
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0033
branche: main
niveau: N1
derniere_maj: 2026-10-20T16:55:41+0200
---

# F01 / M0033 — Installer le dernier build (1.3.0, build 16) sur « iPhone Laura » et sur « iPhone de Malik »

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question que tu aurais posée, les options que tu voyais et celle que tu aurais choisie avec sa raison, puis applique les rituels de fin. Un STOP propre est un rendu valable et laisse l'orchestrateur décider ; une question laisse un mandat mort. Demande d'autorisation d'outil : n'insiste pas, contourne par une commande plus simple ; sans contournement, STOP propre.

Modèle : Haiku 5.5 medium (barème défaut). N1 : aucun code modifié, seuls des fichiers sous `vault/` sont committés.

## Décision du fondateur (20/10/2026)
16:46 « iphone laura envoi le dernier build de l'app ios dessus » ; 16:53 « c'est le cas » (iPhone de Laura branché ou sur le même Wi-Fi, déverrouillé, mode développeur actif) et « profite pour m'envoyer l'app aussi sur mon iphone ».

## Interdits permanents
Jamais de `sleep`, de tâche de fond vivante à la sortie, de `stash`/`reset --hard`/`checkout -- .`/`update-ref`/`pull --rebase --autostash` à la racine, de rebase, de `--no-verify`, de `push --force`. `git add` ciblé, jamais `-A`/`-a`. `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`. **Aucune écriture Supabase. Aucune archive, aucun envoi App Store / TestFlight** (pas de `make release`, pas de `make archive`, pas d'`altool`/`notarytool`). Aucun fichier de code ni `Makefile`/`project.yml` modifié. Commits en heredoc terminés par `Co-Authored-By: Malik & Claude`.

## Contexte
- `origin/main` = `739cbf67b877e09719a3ea8cb1b9861871c63d96` : code de l'app identique au build 16 installé le 19/10 (`995a6d6`, M0026) ; seuls le harnais, le vault et le `Makefile` ont changé depuis. Version : `MARKETING_VERSION 1.3.0`, `CURRENT_PROJECT_VERSION 16` (`project.yml`).
- `main` local (racine) = `63ee5b3`, en retard de 6 commits sur `origin/main` (ancêtre direct).
- iPhone de Malik : UDID `00008101-001278EA36E9001E`, identifiant devicectl `C3CFC878-6C8D-5B87-8B35-1CB108A4922A` (`Makefile`). « iPhone Laura » : connu de devicectl (archive `vault/echanges/archive/2026-10-18-F01-M0014-install-build9.md`, ligne 74) ; son identifiant se lit avec `xcrun devicectl list devices`.
- Méthode d'installation déjà prouvée : archive `vault/echanges/archive/2026-10-19-F01-M0026-build-16-installe.md` (étape 7) et cible `device` du `Makefile` (Debug, signature automatique, `-allowProvisioningUpdates`, puis `devicectl device install app`).

## Garde (tout écart = STOP)
1. `git fetch origin` ; `git rev-parse origin/main` = `739cbf67b877e09719a3ea8cb1b9861871c63d96` ; `git merge-base --is-ancestor main origin/main` rc=0.
2. Racine : `git branch --show-current` = `main` ; `git status --short` ne liste que des fichiers sous `vault/echanges/` (modifiés ou non suivis). Autre chose : STOP.
3. `git merge --ff-only origin/main` à la racine (aligne `main` local) ; `git rev-parse main` = `739cbf6…`, collé. Refus : STOP.

## Mission 0 (racine, `main`, vault seul)
`git add -- vault/echanges/archive/2026-10-20-F01-M0029-nettoyage-github.md`, commit `docs(vault): reconciliation orchestrateur -- archive M0029`, push `main` + `git ls-remote origin refs/heads/main` collé. Ne committe aucun `vault/echanges/Fxx.md` hors `archive/`.

## Travail
1. Worktree détaché : `git worktree add --detach .claude/worktrees/F01-M0033 origin/main` (le SHA d'avant Mission 0 suffit : le code est le même). Tout le build se fait dedans.
2. `xcrun devicectl list devices` (sortie collée). Repère « iPhone Laura » (nom contenant « Laura ») et « iPhone de Malik ». Note pour chacun l'identifiant devicectl et l'UDID matériel (`xcrun devicectl device info details --device <id>` si besoin).
3. **iPhone Laura** : build Debug pour cet appareil, dans le worktree :
   `xcodebuild -scheme BoitesALivresNative -destination 'platform=iOS,id=<UDID Laura>' -configuration Debug -derivedDataPath .build ONLY_ACTIVE_ARCH=YES CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates build` (fin collée). Puis `xcrun devicectl device install app --device <id Laura> .build/Build/Products/Debug-iphoneos/BoitesALivresNative.app`, `xcrun devicectl device process launch --device <id Laura> com.malikkaraoui.boitesalivresapp`, puis `xcrun devicectl device info apps --device <id Laura> --bundle-id com.malikkaraoui.boitesalivresapp` → attendu `1.3.0 16`, collé.
   Échec de signature (appareil absent du profil, compte non connecté dans Xcode) ou téléphone injoignable/verrouillé : **pas un STOP global** ; colle l'erreur exacte, n'essaie rien d'autre que ces commandes, passe à l'étape 4.
4. **iPhone de Malik** : même chose avec `-destination 'platform=iOS,id=00008101-001278EA36E9001E'` et `--device C3CFC878-6C8D-5B87-8B35-1CB108A4922A` (ou `make device` dans le worktree). Vérification `device info apps` → `1.3.0 16`, collée. Injoignable : le dire, pas un STOP.
5. Retire le worktree : `git worktree remove .claude/worktrees/F01-M0033` (et `git worktree prune`). Aucune branche créée.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter, avant tout.
- FIN, dans l'ordre : `## Rapport M0033` dans ce fichier (5 lignes max en français simple : installé ou non sur chaque téléphone, avec la raison exacte si non ; puis les preuves collées) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (écrits, jamais committés) → commit vault ciblé (`vault/reprise/F01.md` et archives) + push `main` + `git ls-remote origin refs/heads/main` collé → footer de statut (gabarit §4 de `.claude/skills/orchestration-bureau/references/gabarits.md`, `M0033` ; Review/Merge sans objet = N/A ; TASK STATUS `INTEGRATED` si les deux installations sont prouvées, sinon `BLOCKED`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0033

- **iPhone Laura : non installé.** Arrêt à la garde 2 : la racine contient des modifications hors `vault/echanges/` (`.claude/skills/orchestration-bureau/SKILL.md`, `.claude/skills/orchestration-bureau/references/gabarits.md`, `config/harnais.json`, `scripts/harnais-hooks/README.md`, `scripts/harnais-hooks/commit-msg`, et `.claude/worktrees/` non suivi). Rien n'a été compilé ni installé.
- **iPhone de Malik : non installé.** Même raison.
- **Mission 0 non faite** (archive M0029 non committée, `main` local non aligné). Le commit vault `5f51d13` est local seulement : push refusé, non fast-forward, `main` local est en retard de six commits sur `origin/main`.
- **Question qui aurait été posée :** faut-il d'abord committer ou ranger les modifications du harnais, à la racine, avant de relancer M0033 ? Options : (a) leur auteur les committe ou les range, puis on relance ; (b) on accepte un `ff-only` malgré les modifications, si elles ne se chevauchent pas. Choix : (a), sans stash ni reset.
- **Décision pour le fondateur :** que faire du commit local `5f51d13` (rebase, ou suppression du commit) ? Je n'ai rien fait là-dessus.

Preuves collées :

```
git fetch origin ; git rev-parse origin/main
739cbf67b877e09719a3ea8cb1b9861871c63d96
git merge-base --is-ancestor main origin/main ; rc=0
git branch --show-current
main
git status --short
 M .claude/skills/orchestration-bureau/SKILL.md
 M .claude/skills/orchestration-bureau/references/gabarits.md
 M config/harnais.json
 M scripts/harnais-hooks/README.md
 M scripts/harnais-hooks/commit-msg
 M vault/echanges/F01.md
 M vault/echanges/F02.md
?? .claude/worktrees/
?? vault/echanges/F03.md ... F06.md, archive/2026-10-20-F01-M0029-nettoyage-github.md
git commit -- vault/reprise/F01.md  -> 5f51d13 docs(reprise): F01 M0033 -- STOP garde 2, rien installé
git push origin main -> rejeté (non-fast-forward)
git ls-remote origin refs/heads/main
739cbf67b877e09719a3ea8cb1b9861871c63d96	refs/heads/main
```

Scellé tests : sans objet (aucun code).
Contre-témoins : sans objet (aucun test).

```
M0033
Implementation      ❌
Tests               N/A
Commit              ✅
Branch push         N/A
Review              N/A
Merge main          N/A
Main push           ❌
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
```
