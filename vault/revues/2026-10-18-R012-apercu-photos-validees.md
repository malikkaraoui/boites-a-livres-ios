---
verdict: GO
tip: 7c7a735e99458a025001c0b9d3ed183ee558d642
niveau: N3
---

# R012 — Doublage N3 : aperçu carte, photos validées essayées dans l'ordre [M0015]

- Worktree détaché : `.claude/worktrees/F02-M0015-R012`, `git rev-parse HEAD` = `7c7a735e99458a025001c0b9d3ed183ee558d642`.
- Diff relu : `c6195fa..7c7a735`, 5 fichiers (BookBox.swift, BookBoxSheet.swift, CHANGELOG.md, project.yml, project.pbxproj). Aucun autre fichier touché : le carrousel de la page détail n'est pas modifié.

## Symptôme #14183 vérifié par le code

photo_url morte, slots [1 mort, 2 mort, 3 vivant] → l'aperçu affiche le slot 3.

1. Ouverture : `failedUrls` vide, `photo_url` présente → `needsList` faux (`BookBoxSheet.swift:28-30`), aucune requête. `imageURL` = photo_url (`:21-23`, `BookBox.swift:92-98`).
2. `CachedAsyncImage` charge photo_url, qui échoue → `onFailure` (`CachedAsyncImage.swift:38-41`) → `failedUrls.insert(url.absoluteString)` (`BookBoxSheet.swift:35`).
3. `needsList` passe à vrai → `.task(id: needsList)` (`:110-115`) lance UNE requête `listPhotos`, puis `validatedUrls = [s1,s2,s3]` et `listLoaded = true`. `needsList` repasse à faux pour de bon, parce que `listLoaded` ne redevient jamais faux : la requête n'est jamais refaite. Pendant la requête, `needsList` reste vrai (`failedUrls` ne fait que grossir), donc la tâche n'est pas annulée en cours de route.
4. Candidates = [photo_url, s1, s2, s3], sans doublon. `current` donne s1 ; le changement d'URL relance `.task(id: url?.absoluteString)` (`CachedAsyncImage.swift:23`). s1 échoue, puis s2 échoue, puis s3 charge et s'affiche.
5. Tout mort : `current` = nil et `listLoaded` → `hidePhoto` (`:26`). Le bloc est masqué. Il n'y a pas de boucle : chaque URL n'est chargée qu'une fois (l'id de la tâche ne change que si l'URL change, et `failedUrls` ne fait que grossir).
6. photo_url nulle : `needsList` est vrai dès l'ouverture → une requête, puis le premier slot qui charge. Liste vide, ou erreur de `listPhotos` (qui renvoie `[]`, `SupabaseService.swift:140-143`) → bloc masqué.
7. État par boîte : `.sheet(item: $vm.selectedBox)` (`MapScreen.swift:176`). Une nouvelle boîte donne une nouvelle identité de vue, donc l'état n'est pas partagé d'une boîte à l'autre.

## Version

- `project.yml:25` `CURRENT_PROJECT_VERSION: 10` ; `project.pbxproj:337` et `:420` `CURRENT_PROJECT_VERSION = 10;` (les 2 seules occurrences).
- `MARKETING_VERSION` = 1.3.0 (`project.yml:24`, pbxproj `:346`, `:429`).
- CHANGELOG `[1.3.0] - non publiée` : « Build 10 », avec une entrée « Aperçu de la carte » cohérente avec le code.

## Tests (harnais propre R012, compilé contre le vrai `BookBox.swift` du worktree)

Harnais : `/private/tmp/claude-501/-Users-malik-Documents-Boites-a-livres-BoitesALivresNative/4affdda4-c848-4b58-b814-676230c6dba2/scratchpad/r012/main.swift`. Il simule aussi la machine d'état de la vue (`needsList`/`listLoaded`/`failedUrls`, les deux `.task(id:)` et `onFailure`) et compte les requêtes et les chargements.
Commande : `swiftc -o r012bin <worktree>/BoitesALivresNative/Models/BookBox.swift main.swift && ./r012bin`

```
OK   A #14183 affiche slot 3: .../14183/3.jpg
OK   A une seule requête: 1
OK   A chaque URL chargée une fois: 4/4
OK   B doublon photo_url=slot1 -> slot 3: .../14183/3.jpg
OK   B pas de rechargement du doublon: 3
OK   C ordre candidats: .../2.jpg .../1.jpg .../3.jpg
OK   C affiche slot 3: .../14183/3.jpg
OK   C 3 chargements, pas de doublon: 3
OK   D photo_url vivante affichée: .../photo_url.jpg
OK   D zéro requête: 0
OK   E photo_url nulle -> slot 2: .../14183/2.jpg
OK   E une requête: 1
OK   F tout mort masqué: masqué
OK   F une requête: 1
OK   F 3 chargements (pas de boucle): 3
OK   G liste vide masqué: masqué
OK   G une requête: 1
OK   H rien du tout masqué: masqué
OK   H une requête: 1
OK   I échec répété ignoré: .../14183/2.jpg
OK   I candidats dédoublonnés dans validated: .../1.jpg .../2.jpg
OK   J roundtrip tes-photos/14183/3.jpg: ...
OK   J roundtrip os/14183/IMG%20001.jpg: ...
OK   J roundtrip oto-1739123456.jpg?t=1: ...
OK   K naïf échoue sur #14183 comme attendu: shown=nil
RESULTAT: tous verts
exit=0
```

Cas absents du harnais du correctif : C (doublon photo_url = slot 2, en position non initiale), D (zéro requête si photo_url vit), G et H (liste vide), I (URL répétée, déjà en échec), J (la clé `absoluteString` redonne bien la chaîne candidate), et le décompte des requêtes et des chargements.

### Preuve que le test peut échouer

Cas K : la même simulation, avec un `current` naïf (photo_url, puis seulement `validated.first`), sur #14183 → `shown=nil` (bloc masqué), alors que le correctif affiche le slot 3. Le harnais distingue donc l'ancien comportement du nouveau. S'il passait à tort, K compterait un rouge.

## Build

`xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` (derivedData et log dans `scratchpad/r012/`) → `** BUILD SUCCEEDED **`, exit 0. 3 avertissements, aucun dans les fichiers modifiés.

## Risques résiduels

- Non vérifié à l'écran (pas d'iPhone ici). La simulation reproduit la logique des `.task(id:)`, mais pas l'ordonnancement réel de SwiftUI.
- Pendant la requête `listPhotos` après l'échec de photo_url, `imageURL` vaut nil et `hidePhoto` est faux. Le bloc image disparaît donc brièvement, puis revient (saut de mise en page possible dans la sheet). C'est cosmétique.
- Si une candidate n'est pas une URL parsable, `URL(string:)` renvoie nil, et `imageURL` vaut nil sans que l'échec soit enregistré. Le bloc est alors masqué même si une candidate suivante est valide. C'est théorique avec les URL Supabase (cas J vert).
- Chaque photo morte coûte un aller-retour réseau en série avant d'atteindre la vivante (3 pour #14183).

## Issues proposées (non bloquantes)

1. Garder le placeholder (ProgressView) pendant le chargement de la liste, au lieu de retirer le bloc : `if imageURL != nil || needsList`.
2. Filtrer les candidates non parsables dans `PreviewPhotoPicker.candidates` (`compactMap URL`), pour qu'une chaîne invalide ne masque pas les suivantes.
3. Hauteur du detent `small` (`MapScreen.swift:177`) : elle vaut 200 si photo_url est nulle, même quand une photo validée s'affiche. À vérifier visuellement (image de 140 px dans une sheet de 200).

## Checklist écran pour le fondateur

- [ ] Build 10 installé (Réglages > Général > Informations, ou TestFlight).
- [ ] Carte → boîte #14183 : l'aperçu montre une photo (le slot 3), pas de bloc vide ni d'icône « photo » grise qui reste affichée.
- [ ] Une boîte dont la photo charge normalement : l'aperçu s'affiche tout de suite, sans clignotement.
- [ ] Une boîte sans aucune photo : pas de bloc image, la sheet reste compacte.
- [ ] Rouvrir #14183 deux ou trois fois : comportement identique, pas de clignotement en boucle.
- [ ] Page détail de #14183 : le carrousel n'a pas changé.
