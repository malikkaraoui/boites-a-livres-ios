---
date: 2026-10-25
revue: R050
mandat: M0060
branche: fix/reglages-rechargement
base: 26a2427fa83aec8513308beaa86baaa2320c8466
tip: a3375ef3a787a48227e11fac7ab2c2c489fbfa41
niveau: N3
verdict: GO
---

# R050 — Réglages : rechargement à l'ouverture et au retour dans l'app (M0060, #67)

Relecture indépendante par un sous-agent frais (Haiku, lecture seule, worktree détaché sur `a3375ef`). Citations recontrôlées par la session mère sur le même commit.

## Contrôles

- **R1 déclencheurs : OK.** `App/ContentView.swift:41` passe `isSelected: selectedTab == 2` ; `App/SettingsView.swift:68` `.task(id: isSelected)` ; `:73-74` retour au premier plan gardé par `phase == .active, isSelected` ; `:77` `.refreshable { await vm.reload() }`.
- **R2 concurrence : OK.** `ViewModels/SettingsViewModel.swift:18` `inFlight`, `:22-31` test et création sans suspension entre les deux (MainActor) ; `:29` remise à nil dans la tâche, après `load()`. Aucune liste vidée avant la réponse (`:37-` : assignations après les `await`).
- **R3 périmètre : OK.** Huit fichiers, tous attendus. `MapScreen` non modifié ; `SettingsView(` a une valeur par défaut, aucun autre appelant.
- **R4 version 30 : OK.** `project.yml:25`, `project.pbxproj:425` et `:508` = 30 ; `MARKETING_VERSION` = 1.3.0 ; `CHANGELOG.md` section « Build 30 » ; `release-notes/fr-FR.txt:1` et `en-US.txt:1` = « build 30 ».
- **R5 débogage résiduel : OK.** Aucun « TEMPORAIRE », « F02MARQUE » ni « f02-journal » dans le code livré.
- **R6 risques Swift : pas de défaut prouvé.** Capture forte transitoire (rompue par `inFlight = nil`) ; `.task(id:)` relancé à chaque affichage sans fuite.

## Remarques non bloquantes (deviennent une issue)

1. Un tirer-pour-rafraîchir lancé pendant un chargement déjà en cours attend ce chargement sans en lancer un nouveau : les données peuvent précéder une écriture survenue entre-temps. Fenêtre étroite.
2. Erreur réseau : `try? … ?? []` remplace une liste par `[]` (comportement hérité, non introduit par le diff).

## Contrôles de la session mère

- Budget : `sh scripts/harnais-hooks/pre-commit --controle a3375ef… --base 26a2427…` → 4 OK, 0 ATTENTION, 0 BLOQUÉ.
- Fusion testée (`caf3b01`) : build Release `BUILD SUCCEEDED` ; `node --test scripts/release/asc.test.mjs` : 17 pass, 0 fail.
- Simulateur (test UI temporaire, retiré avant commit) : rechargement une fois à l'ouverture de Réglages, une fois au retour au premier plan Réglages affiché, aucun au retour au premier plan sur Carte.

## Verdict

GO. Aucune réserve prouvée par un test rouge.
