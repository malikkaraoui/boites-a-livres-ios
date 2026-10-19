---
date: 2026-10-19
tags: [publication, app-store-connect, outillage]
session: F01
mandat: commande-publication-app-store
mandat_id: M0027
statut: reponse-disponible
commande: cd '/Users/malik/Documents/Boites-a-livres/BoitesALivresNative' && claude --dangerously-skip-permissions --disallowedTools ScheduleWakeup,CronCreate --settings '/Users/malik/.harnais/hooks.json' --model 'claude-haiku-5-5' --effort 'medium' 'Va lire ton prompt dans vault/echanges/F01.md et exécute-le. Applique strictement les rituels décrits.'
worktree: /Users/malik/Documents/Boites-a-livres/BoitesALivresNative/.claude/worktrees/F01-M0027
branche: feat/publication-app-store
niveau: N3
derniere_maj: 2026-10-19T23:20:06+02:00
---

# F01 / M0027 — Une commande de publication App Store (sans passer par le site), **sans rien publier dans ce mandat**

**Tu ne poses JAMAIS de question et tu n'attends JAMAIS de réponse.** Si tu es sur le point de demander un arbitrage, c'est un **STOP** : question, options et choix motivé au rapport, puis rituels de fin. Demande d'autorisation d'outil : sans contournement, STOP propre.

Modèle : Haiku 5.5 medium. N3 (`Makefile` est critique). Doublage par sous-agent FRAIS, même modèle.

## INTERDIT ABSOLU DANS CE MANDAT
**Aucun envoi de build chez Apple, aucune création ou modification de version, de notes ou de soumission sur App Store Connect.** Uniquement des **lectures** (requêtes GET) de l'API App Store Connect pour prouver que la clé fonctionne. La règle du fondateur reste : rien vers l'App Store ni TestFlight sans son « OK Apple » explicite.
Ne jamais afficher, copier, committer ni journaliser le contenu de la clé `.p8` ni un jeton signé.

## Décision du fondateur (19/10/2026, 23:06-23:11)
« Oui à fond » : publier une nouvelle version sans passer par https://appstoreconnect.apple.com (envoi du build, notes de version, soumission à la revue) par une commande. Clé créée par le fondateur :
- Key ID : `G2GFLJVZ6B` ; Issuer ID : `69a6de91-66b4-47e3-e053-5b8c7c11a4d1` (identifiants non secrets) ;
- fichier : `~/.appstoreconnect/private_keys/AuthKey_G2GFLJVZ6B.p8` (secret, hors dépôt, permissions 600).
App : bundle `com.malikkaraoui.boitesalivresapp`, équipe `UPES5479T5`, App Store id `6768351762`.

## Ce que tu livres (branche `feat/publication-app-store`)
1. **Configuration hors dépôt** : `~/.appstoreconnect/config.env` (créé s'il manque, permissions 600) avec `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`. Dans le dépôt : `scripts/release/config.env.example` (valeurs factices) et `.gitignore` qui exclut tout `*.p8` et `config.env`.
2. **Zéro dépendance ajoutée** : envoi du build par `xcodebuild -exportArchive` (ExportOptions `method app-store-connect`, `destination upload`) avec `-allowProvisioningUpdates -authenticationKeyPath -authenticationKeyID -authenticationKeyIssuerID` ; métadonnées et soumission par un script **Node** sans paquet (`scripts/release/asc.mjs` : jeton ES256 signé avec `node:crypto`, appels `fetch` à `https://api.appstoreconnect.apple.com/v1/…`). Si l'une de ces briques ne marche pas (option xcodebuild absente de la version installée, etc.), STOP propre avec la preuve ; ne bascule pas sur fastlane sans décision du fondateur.
3. **Notes de version** : `release-notes/fr-FR.txt` (texte « Nouveautés » de la version), rempli à partir de `CHANGELOG.md` (builds 14 à 16) en français simple, ≤ 4000 caractères, à faire relire par le fondateur avant publication.
4. **Commandes `Makefile`** :
   - `make release-check` : lecture seule. Vérifie la clé (GET `/v1/apps?filter[bundleId]=…`), affiche la version en ligne sur l'App Store, son état, les versions en préparation et les derniers builds reçus. Code de sortie ≠ 0 si la clé est refusée.
   - `make release CONFIRMER=OK-APPLE` : refuse de démarrer sans `CONFIRMER=OK-APPLE` exactement. Enchaîne : contrôle des numéros (MARKETING_VERSION > version en ligne, build > dernier build reçu), archive, envoi du build, attente du traitement du build par Apple (sondage borné, message clair), création ou mise à jour de la version App Store, « Nouveautés » depuis `release-notes/fr-FR.txt`, rattachement du build, soumission à la revue. Chaque étape annonce ce qu'elle fait ; toute erreur arrête tout avec le message d'Apple.
   - Documentation courte dans `scripts/release/README.md` (commande, prérequis, ce que fait chaque étape).
5. Tests **sans envoi** : `node --test` pour `asc.mjs` (signature du jeton vérifiée localement avec la clé publique dérivée, construction des requêtes, garde `OK-APPLE`, comparaison des versions) ; `make release` sans `CONFIRMER` ⇒ refus (sortie collée) ; `make release-check` réel (lecture) ⇒ sortie collée (sans aucun secret). Si `release-check` est refusé par Apple : coller le message, STOP propre (le reste du travail reste poussé).

## Garde (tout écart = STOP)
1. `git fetch origin` ; `git rev-parse main origin/main` = deux fois `dff325333d954da469308b4b0a8f476812788602`.
2. `git status --short` racine : exactement `M vault/echanges/F01.md`, `M vault/echanges/F02.md`, `?? .claude/worktrees/` et des non suivis sous `vault/echanges/`.
3. `test -r ~/.appstoreconnect/private_keys/AuthKey_G2GFLJVZ6B.p8` (lisible ; n'affiche pas son contenu).

## Mission 0 (racine, `main`, vault seul)
`git add -- vault/echanges/archive/2026-10-19-F01-M0026-build-16-installe.md`, commit `docs(vault): reconciliation orchestrateur -- archive M0026`, push `main` + `git ls-remote origin refs/heads/main` collé.

## Déroulé
1. Branche depuis `origin/main`, worktree `.claude/worktrees/F01-M0027`. Commits ciblés. Push + `ls-remote` collé. Tip = `T`.
2. **Doublage N3 R023** (`next_revue_id` relu) : sous-agent FRAIS, worktree détaché lecture seule ; vérifie surtout : aucun secret dans le dépôt ni dans les sorties, la garde `OK-APPLE` ne peut pas être contournée, aucune requête d'écriture exécutée pendant le mandat, contrôle des numéros, arrêt sur erreur, zéro dépendance ; budget `sh "$(git config core.hooksPath)/pre-commit" --controle T --base $(git merge-base origin/main T)` collé. `vault/revues/2026-10-19-R023-publication-app-store.md`, frontmatter fermé : une ligne `verdict:`, une ligne `tip:` (sha 40), une ligne `niveau: N3`. Réserve prouvée → correctif + R024 en chaîne, une fois, sinon STOP.
3. Si GO : merge gabarit §9 mode direct (`.claude/skills/orchestration-bureau/references/gabarits.md`, lu en entier). Push `main` + `ls-remote` collé. Refus du hook : STOP, jamais `--no-verify`. Retire les worktrees.

## Sous-agents (gabarit §3)
(1) agents FRAIS, jamais `fork` ; (2) aucun sous-agent ne commit, ne pousse, ne modifie `vault/runtime/` ni `vault/reprise/`, n'appelle l'API Apple en écriture ni ne tue un autre agent ; (3) rapport vérifié (fichier:ligne) ; (4) après incident : `git status`/`diff`/`log`/`reflog` d'abord ; (5) attendre le retour de tous avant les rituels de fin (jamais `sleep`) ; échec = STOP propre.

## Interdits
Jamais `sleep` (le sondage borné du traitement Apple n'est pas exécuté dans ce mandat), tâche de fond vivante, `stash`, `reset --hard`, `checkout -- .`, `update-ref`, `--no-verify`, `push --force`. `git add` ciblé. `rm -rf` seulement `"${VAR:?}/${SOUS:?}"`.

## Rituels
- DÉBUT : `statut: en-cours` à la racine du frontmatter.
- FIN, dans l'ordre : `## Rapport M0027` (5 lignes max en français simple, puis preuves ; dire la version en ligne sur l'App Store et ce que fera `make release CONFIRMER=OK-APPLE`) → `vault/reprise/F01.md` → `vault/runtime/events.jsonl` + `state.json` (non committés ; `next_revue_id` avancé) → commit vault ciblé + push + `ls-remote` collé → footer de statut (gabarit §4, `M0027`) → **`statut: reponse-disponible` posé EN DERNIER GESTE**.

## Rapport M0027

En français simple : la commande de publication est écrite, testée et mergée sur `main` (`323ab4d`). Elle n'a **rien envoyé** : ni build, ni version, ni soumission. `make release-check` (lecture) prouve que la clé marche : la version en ligne sur l'App Store est **1.2.0**, et le dernier build reçu est le **5**. `make release CONFIRMER=OK-APPLE` enverra le build 1.3.0 (16), créera la version 1.3.0, mettra les notes de `release-notes/fr-FR.txt`, puis soumettra à la revue : seulement après ton OK Apple explicite, et après relecture des notes.

- Doublage R023 : BLOQUE au tip `3b343f9` (listing des versions tronqué à 10 : un contrôle de version en ligne pouvait être sauté). Correctif `da88ba6` (pagination complète, tests de régression). Passe R024 sur `da88ba6` : GO. Rapport `vault/revues/2026-10-19-R023-publication-app-store.md` (frontmatter `verdict: GO`, `tip: da88ba6…`, `niveau: N3`).
- Remarques non bloquantes, consignées en issue #33 (pas de nouveau tour). Une point à connaître : l'envoi du build a lieu avant le contrôle des versions en cours de revue ; à durcir avant le premier envoi réel.
- Choix faits : la config est dans `~/.appstoreconnect/config.env` (chmod 600), hors dépôt ; `ExportOptions.plist` ajouté dans `scripts/release/` ; le sondage de traitement est borné à 40 essais de 30 s. `R024` a servi de revue de chaîne, sans fichier séparé ; `next_revue_id` est passé à `R025`.

Preuves :
- Garde : `main` = `origin/main` = `dff3253` à l'ouverture ; statut conforme ; clé `.p8` lisible en 600.
- Mission 0 : archive M0026 committée `802ff9c`, `ls-remote refs/heads/main` = `802ff9c`.
- Branche `feat/publication-app-store` : `3b343f9` puis `da88ba6`, `ls-remote` = `da88ba6eb56a257ede590c27d8f6895fdb2555c8`.
- Tests : `node --test scripts/release/asc.test.mjs` = 11 pass, 0 fail (sur le scratch fusionné aussi).
- Refus : `make release` sans confirmation, et avec `ok-apple` : « Refus : make release exige CONFIRMER=OK-APPLE exactement. Aucune action lancée. », exit 2.
- Lecture réelle : `make release-check` exit 0 : App `Boîtes à livres` (id 6768351762) ; versions 1.2.0, 1.1.0, 1.0.0 (READY_FOR_SALE) ; builds 5, 5, 4 (VALID). Aucune écriture.
- Budget : `controle-instructions` 4 OK, 0 ATTENTION, 0 BLOQUE.
- Merge direct : scratch `f6a49c0` (merge `--no-ff` de `da88ba6`), rapport R023 `323ab4d`, `ff-only` depuis la racine, `git push origin main` : `802ff9c..323ab4d` ; `ls-remote refs/heads/main` = `323ab4d72d836e5777f2a8cac5d57ff2c5c8650c`.
- Reprise committée `8e94a2d` ; `ls-remote` = `8e94a2dc4fb47e370d847b180e8f29f849a0e4b4`.
- Worktrees `F01-M0027` et `F01-M0027-merge` retirés. Branche distante conservée.

Mandat rendu, rien d'autre n'a été écrit sur App Store Connect.

M0027
Implementation      ✅
Tests               ✅
Commit              ✅
Branch push         ✅
Review              ✅
Merge main          ✅
Main push           ✅
TASK STATUS         INTEGRATED
PROJECT STATUS      INTEGRATED
