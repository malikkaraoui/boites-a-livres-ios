---
date: 2026-10-18
tags: [doublage, photos, N3]
session: F02
mandat: doublage-photos-validees
mandat_id: R010
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F02.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F02-R010
branche: fix/photos-validees
niveau: N3
derniere_maj: 2026-10-18T16:20:43+0200
---

# F02 / R010 — Doublage N3 indépendant de `fix/photos-validees` (M0010) + merge

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Personne n'est devant l'écran. Si tu es sur le point de demander un arbitrage, c'est un **STOP** : écris dans ton rapport la question que tu aurais posée, les options que tu voyais et celle que tu aurais choisie avec sa raison, puis applique les rituels de fin. Un STOP propre est un rendu valable et laisse l'orchestrateur décider ; une question laisse un mandat mort. Vaut aussi pour une demande d'autorisation d'outil : n'insiste pas ; contourne par une commande plus simple (lecture seule, `git show`, `git -C`, chemin explicite) ; sinon STOP propre.

## Interdits permanents
- Jamais de `sleep`, jamais de tâche de fond vivante à la sortie ; `rm -rf` seulement sous forme gardée `"${VAR:?}/${SOUS:?}"`.
- Git : `git add` ciblé, jamais `-a`/`-A` ; jamais `stash`/`reset --hard`/`checkout -- .` à la racine ; jamais de rebase ; jamais `--no-verify`.
- **AUCUNE écriture en production Supabase** (base ou stockage) dans ce mandat : lecture seule, et tests sur données simulées.
- Ne jamais afficher ni écrire une clé (service ou anon) dans un fichier suivi, un log ou le rapport.
- Signature des commits : message en heredoc terminé par `Co-Authored-By: Malik & Claude`.

## Sous-agents (gabarit §3, verbatim)
(1) lecture/recherche parallèle = agents FRAIS (jamais `fork`) ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, ni ne tue un autre agent ; (3) tout rapport de sous-agent est VÉRIFIÉ (fichier:ligne recontrôlés) avant le livrable ; (4) après tout incident : git status/diff/log/reflog AVANT toute autre action ; (5) ATTENDRE LE RETOUR DE TOUS les sous-agents avant le premier rituel de fin — jamais `sleep` ni sondage ; échec de l'un = STOP propre.

## Tu es le DOUBLEUR, pas l'auteur
Auteur : session M0010 (rapport : `vault/echanges/archive/2026-10-18-F01-M0010-photos-validees.md`, à lire en entier). Tu ne corriges rien sur la branche : tu juges. Worktree **détaché lecture seule** `.claude/worktrees/F02-R010` sur `66123e859df2a44c284b16b7ebfb1500a192cdd8`. Lis `.claude/skills/orchestration-bureau/SKILL.md` §9 en entier avant.

## Garde
- `git fetch origin` ; `git rev-parse origin/fix/photos-validees` = `66123e859df2a44c284b16b7ebfb1500a192cdd8` ; sinon STOP.
- Garde d'entrée §9 : `git log $(git merge-base origin/main 66123e859df2a44c284b16b7ebfb1500a192cdd8)..origin/main -- <chemins du diff>` doit être vide (fichiers intacts côté main), sinon STOP.

## Mission
1. Lire le diff au tip (`git show 66123e859df2a44c284b16b7ebfb1500a192cdd8:<chemin>`, `git diff $(git merge-base origin/main 66123e859df2a44c284b16b7ebfb1500a192cdd8)..66123e859df2a44c284b16b7ebfb1500a192cdd8`). Vérifier le **SYMPTÔME d'origine** : (a) les photos validées (`book_box_photos`) sont affichées ; (b) aucune photo en attente (`<boxId>/` du stockage) n'est plus lue ni affichée ; (c) une `photo_url` morte ne laisse pas de carré gris si une autre photo existe, aperçu carte compris ; (d) la limite de 3 compte les slots validés. Contre-vérifier : plus aucune lecture `storage/v1/object/list` dans l'app (grep collé) ; dédoublonnage ; repli sur `photo_url` si la requête échoue ; version (CURRENT_PROJECT_VERSION 9, MARKETING_VERSION 1.3.0) et CHANGELOG.
2. Rejouer : build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` + le harnais `PhotoList.merge` décrit par l'auteur (sortie collée). Lecture réelle anon `GET /rest/v1/book_box_photos?box_id=eq.14183&select=slot,url&order=slot.asc` (clé jamais affichée) → coller code et nb de lignes.
   Rapport `vault/revues/2026-10-18-R010-photos-validees.md` : frontmatter fermé par `---`, EXACTEMENT une ligne `verdict: GO|RESERVE`, une ligne `tip: 66123e859df2a44c284b16b7ebfb1500a192cdd8`, une ligne `niveau: N3`. Verdict **par axe** (symptôme, sûreté, tests, version, UX) avec la raison vérifiée.
   **Règle du projet (à appliquer strictement)** : une réserve ne bloque (`RESERVE`) que si un **test rouge** la prouve, ou un axe ⛔ exigé par §9 (symptôme non résolu, budget `BLOQUE`). Tout le reste = **remarque** → ouvre une issue GitHub (`gh issue create`, lien au rapport), jamais un nouveau tour. L'absence de preuve d'écran (pas d'iPhone/émulateur pilotable) = axe UX « ⚠️ non vérifié à l'écran » + checklist fondateur reprise du rapport auteur : **ce n'est pas une réserve bloquante**.
3. **Si GO** : merge selon `.claude/skills/orchestration-bureau/references/gabarits.md` §9 mode direct, lu EN ENTIER avant (branche `fix/photos-validees`, tip `66123e859df2a44c284b16b7ebfb1500a192cdd8`, revue `R010`, rapport committé dans le scratch avant le `ff-only`). Avant : `git rev-parse main origin/main` identiques, sinon STOP. **Tests rejoués sur le scratch** (build Release `xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` + le harnais `PhotoList.merge` décrit par l'auteur) : rouges = pas de `ff-only`, STOP. Push + `git ls-remote origin refs/heads/main` collé. Puis `git worktree remove` du scratch et du worktree de doublage.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN : rapport `## Rapport R010` **dans ce fichier `vault/echanges/F02.md`** (en tête 5 lignes max en français simple) → `vault/reprise/F02.md` → `vault/runtime/events.jsonl` + `state.json` (non committés) → commit vault ciblé (si `main` local = `origin/main`) + push + `ls-remote` collé → footer (gabarit §4) → **`statut: reponse-disponible` EN DERNIER GESTE**.

## Rapport R010

En français simple : le correctif M0010 (photos validées seulement, build 9) est **GO sur le code** : build Release et deux harnais rejoués au tip, tout vert. **Je n'ai pas fusionné sur `main`** : le merge se heurte à un conflit sur `vault/reprise/F01.md` (les deux côtés réécrivent tout le fichier), et le gabarit dit de s'arrêter dans ce cas. Ton arbitrage : je recommande de garder la version `main` de ce registre et de déplacer la reprise M0010 dans son rapport archivé ; je relance alors le merge sur ce tip. Six remarques sont ouvertes en issues (#12 à #17), l'écran n'est pas vérifié (checklist dans la revue).

- Revue : `vault/revues/2026-10-18-R010-photos-validees.md` (`verdict: GO`, `tip: 66123e8…`, `niveau: N3`), verdict par axe, preuves, remarques et checklist fondateur.
- Garde d'entrée : tip `origin/fix/photos-validees` = `66123e8` ; `main` = `origin/main` = `da6e45f` ; fichiers du diff intacts côté `main` (`git log` vide).
- Tests rejoués sur le tip : build Release `** BUILD SUCCEEDED **` ; harnais de l'auteur `ALL PASS` (6 cas) ; harnais indépendant `ALL PASS` (9 cas, code extrait du tip). Budget `pre-commit --controle` : 4 OK, 0 BLOQUE.
- Lecture réelle anon `book_box_photos?box_id=eq.14183` : HTTP 200, 3 lignes. Slots 1-2 hors `approved/` : signalé à l'admin (issue #15).
- Merge : scratch `F02-merge` détaché sur `origin/main`, `merge --no-ff 66123e8` → conflit unique sur `vault/reprise/F01.md` (marqueurs l.4, 40, 54). `merge --abort` puis retrait du scratch. Rien poussé sur `main`.
- Remarques : issues https://github.com/malikkaraoui/boites-a-livres-ios/issues/12 à /17.
- Constat : `vault/echanges/F02.md` (ce mandat) n'est pas commité ; il reste le registre vivant de cette fenêtre, comme le veut l'ordre des rituels (statut en dernier).

R010
Implementation      N/A
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ❌
Main push           ❌
TASK STATUS         BLOCKED
PROJECT STATUS      NOT_INTEGRATED
