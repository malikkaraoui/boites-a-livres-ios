---
date: 2026-11-05
revue: R057
mandat_id: M0070
branche: fix/conformite-export-plist
tip: 05f36b1c9c741289ca7dd024b8a5e47cef86e3c1
niveau: N3
verdict: GO
---

# R057 — Conformité à l'exportation (Info.plist) et cause Apple lisible (asc.mjs)

Relecteur indépendant (n'est pas l'auteur). Lecture au tip `05f36b1` dans le worktree détaché
`.claude/worktrees/F02-R057` (HEAD = `05f36b1c9c741289ca7dd024b8a5e47cef86e3c1`, `git status --short` vide
avant comme après les vérifications). Base `c07d4f0` = `origin/main` (vérifié par `git rev-parse origin/main`).
Aucun commit, aucun push, aucun appel App Store Connect.

## Verdicts par axe

| Axe | Verdict | Raison vérifiée |
|---|---|---|
| Conformité / chiffrement | ✅ GO | Le seul usage cryptographique du code Swift (44 fichiers) est `CryptoKit.SHA256` pour nommer des fichiers de cache (`LocalCacheService.swift:75`, `ImageCacheService.swift:81`). Aucun chiffrement de données (pas d'AES, ChaChaPoly, SealedBox, SymmetricKey, SecKey, CommonCrypto, Keychain). Aucune dépendance SPM, CocoaPods ou Carthage, aucun framework embarqué, aucun source C/ObjC. Le hachage n'est pas du chiffrement, et le réseau passe par le HTTPS du système : l'exemption s'applique, donc `false` est la bonne valeur. |
| Info.plist (N3) | ✅ GO | La clé est ajoutée au bon niveau, avec le type `<false/>`. `plutil -lint` est OK. Les deux configurations utilisent `INFOPLIST_FILE = BoitesALivresNative/Info.plist`, et la cible app ne déclare aucun `INFOPLIST_KEY_ITSAppUses…` concurrent (les `GENERATE_INFOPLIST_FILE = YES` concernent les cibles de test). La clé est présente et vaut `false` dans l'app Release produite. |
| asc.mjs : sécurité | ✅ GO | Le message ne contient que la méthode, `url.pathname` (sans la query string), le statut et des champs de la réponse d'Apple (`title`, `detail`, `code`, `source.pointer`, clés de `associatedErrors`). Les en-têtes envoyés n'y figurent jamais. La sonde d'intégration confirme que le jeton Bearer est absent du message (`false`). |
| asc.mjs : correction | ✅ GO (⚠️ R1) | Le comportement est inchangé quand `associatedErrors` est absent (`'T D'`). `{}`, `null` et `errors: null` donnent `''`, puis le repli sur `text.slice(0, 200)`. Avec `associatedErrors` à null, ou une liste à null, le résultat est propre. L'intégration dans `makeClient` est vérifiée : un 409 lève `AscError` avec la cause `socialMedia` et son pointeur. Un cas limite est décrit en R1. |
| Tests | ✅ GO | 18/18 au tip. Le test est rouge contre `c07d4f0`, de deux façons : export absent, et ancienne logique isolée où l'assertion échoue sur la cause manquante. |
| Build | ✅ GO | `** BUILD SUCCEEDED **` en Release `generic/platform=iOS`. PlistBuddy affiche `false`. |
| Budget | ✅ GO | 4 OK, 0 ATTENTION, 0 BLOQUE. |
| Docs | ✅ GO (⚠️ R3) | `scripts/release/README.md:36` (« affiche le message d'Apple ») reste exact, et le message est maintenant plus complet. Le seul CLAUDE.md du worktree est celui de la racine (45 caractères, un import). Aucun comportement décrit n'est contredit. |

## Sorties collées

### 1. Garde d'entrée (doit être vide)

```
$ git -C <racine> log $(git -C <racine> merge-base origin/main 05f36b1)..origin/main -- BoitesALivresNative/Info.plist scripts/release/asc.mjs scripts/release/asc.test.mjs
--garde--
--fin garde--
```
La sortie est vide. `git log --oneline c07d4f0..05f36b1` → `05f36b1 fix(release): conformite export dans Info.plist, cause Apple lisible` (un seul commit).

### 2. Diff `c07d4f0..05f36b1`, relu en entier

```diff
--- a/BoitesALivresNative/Info.plist
+++ b/BoitesALivresNative/Info.plist
@@ -18,6 +18,8 @@
     <key>CFBundleVersion</key>
     <string>$(CURRENT_PROJECT_VERSION)</string>
+    <key>ITSAppUsesNonExemptEncryption</key>
+    <false/>
     <key>LSRequiresIPhoneOS</key>
--- a/scripts/release/asc.mjs
+++ b/scripts/release/asc.mjs
+export function describeErrors(json) {
+  const parts = [];
+  for (const e of json?.errors ?? []) {
+    parts.push(`${e.title ?? ''} ${e.detail ?? ''}`.trim());
+    for (const [res, list] of Object.entries(e.meta?.associatedErrors ?? {})) {
+      for (const a of list ?? []) {
+        const where = a.source?.pointer ? ` (${a.source.pointer})` : '';
+        parts.push(`${res} : ${a.detail ?? a.title ?? a.code ?? '?'}${where}`);
+      }
+    }
+  }
+  return parts.join(' | ');
+}
-      const detail = (json.errors ?? []).map((e) => `${e.title ?? ''} ${e.detail ?? ''}`.trim()).join(' | ') || text.slice(0, 200);
+      const detail = describeErrors(json) || text.slice(0, 200);
--- a/scripts/release/asc.test.mjs
+++ b/scripts/release/asc.test.mjs
 (import de describeErrors + test « erreur Apple : la cause cachée dans associatedErrors est citée »)
```

### 3. Tests et lint au tip (worktree F02-R057)

```
✔ listVersions refuse une pagination trop longue au lieu de tronquer (0.080334ms)
✔ erreur Apple : la cause cachée dans associatedErrors est citée (0.076ms)
ℹ tests 18
ℹ pass 18
ℹ fail 0
$ plutil -lint BoitesALivresNative/Info.plist
BoitesALivresNative/Info.plist: OK
```

### 4. Témoin rouge (copies dans /private/tmp/claude-501/r057-red, hors dépôt)

A. Test de `05f36b1` contre l'`asc.mjs` de `c07d4f0`, tel quel (l'import `describeErrors` est absent) :
```
✖ asc.test.mjs (54.46925ms)
ℹ tests 1
ℹ pass 0
ℹ fail 1
```
B. Même chose, mais l'ancienne expression du `throw` (c07d4f0) est exposée sous le nom `describeErrors`, pour prouver que l'assertion elle-même échoue :
```
✖ erreur Apple : la cause cachée dans associatedErrors est citée (0.9435ms)
  AssertionError [ERR_ASSERTION]: The input did not match the regular expression /ageRatingDeclarations\/v1 : You must provide a value for the attribute 'socialMedia'/. Input:
    actual: "appStoreVersions with id 'v1' is not in valid state. This resource cannot be reviewed, please check associated errors to see why.",
```

### Sonde complémentaire (asc.mjs du tip, /private/tmp/claude-501/r057-probe)

```
integration: true 409 | GET /v1/apps -> HTTP 409 : not in valid state see associated | /v1/ageRatingDeclarations/x : attr 'socialMedia' (/data/attributes/socialMedia)
jeton dans message ? false
vide => ""
null => ""
errorsNull => ""
assocNull => "T"
listNull => "T"
sansChamps => " | r : ?"
codeSeul => "T | r : X"
listObjet => THROW TypeError (list ?? []) is not iterable
itemNull => THROW TypeError Cannot read properties of null (reading 'source')
errorNull => THROW TypeError Cannot read properties of null (reading 'title')
```
(`errorNull` levait déjà une TypeError dans `c07d4f0` : ce n'est pas une régression.)

### Chiffrement : recherche dans le code et les dépendances

```
$ grep -rnE 'CryptoKit|CommonCrypto|CCCrypt|CCHmac|SecKey|AES|ChaChaPoly|SealedBox|SymmetricKey|import Security|SecItem|Insecure\.|HMAC|Curve25519|P256|kSecAttr|SHA256|SHA512|Encrypt|encrypt|cipher' --include='*.swift' .
BoitesALivresNative/Services/LocalCacheService.swift:2:import CryptoKit
BoitesALivresNative/Services/LocalCacheService.swift:75:        let digest = SHA256.hash(data: Data(zone.utf8))
BoitesALivresNative/Services/ImageCacheService.swift:3:import CryptoKit
BoitesALivresNative/Services/ImageCacheService.swift:7:/// Two-tier image cache: memory (NSCache) + disk (Caches/ImageCache). Key = SHA256(url). ...
BoitesALivresNative/Services/ImageCacheService.swift:81:        let hash = SHA256.hash(data: data)
swift files: 44
Package.resolved / Package.swift / Podfile / Cartfile : aucun
project.pbxproj : XCRemoteSwiftPackageReference / XCSwiftPackageProductDependency = 0 ; packageProductDependencies = ( ) vide
*.m *.mm *.c *.cpp *.h hors scripts : aucun ; *.framework / *.xcframework : aucun
NSAllowsArbitraryLoads / http:// en Swift : aucun (seul le DOCTYPE du plist)
```

### 5. Build Release générique

```
$ xcodebuild -scheme BoitesALivresNative -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/claude-501/r057-dd CODE_SIGNING_ALLOWED=NO build
exit=0
** BUILD SUCCEEDED **
-rw-r--r--  1 malik  wheel  2503  5 nov.  18:19 .../Release-iphoneos/BoitesALivresNative.app/Info.plist
$ /usr/libexec/PlistBuddy -c 'Print :ITSAppUsesNonExemptEncryption' <app>/Info.plist
false
  "CFBundleShortVersionString" => "1.4.0"
  "CFBundleVersion" => "34"
  "ITSAppUsesNonExemptEncryption" => false
```
(Le plist est daté de 18:19, l'heure du build : il a bien été produit par ce build.)

### 6. Budget des fichiers chargés d'office

```
OK        .claude/skills/orchestration-bureau/SKILL.md : 29078 caracteres (seuil 40000), ligne la plus large 399 (seuil 400)
OK        CLAUDE.md : 45 caracteres (seuil 40000), ligne la plus large 44 (seuil 400)
OK        vault/reprise/00_INDEX.md : 1973 caracteres (seuil 80000), ligne la plus large 107 (seuil 400)
OK        vault/reprise/CARNET_DE_BORD.md : 1115 caracteres (seuil 40000), ligne la plus large 200 (seuil 400)
controle-instructions : 4 fichier(s) charge(s) d'office dans 05f36b1c9c741289ca7dd024b8a5e47cef86e3c1 (base c07d4f0a5a2056c48e1630c98a22c72b45f54f53) -- 4 OK, 0 ATTENTION, 0 BLOQUE
exit=0
```

### 7. Docs

- `scripts/release/README.md:36` dit : « Toute erreur arrête tout et affiche le message d'Apple ». C'est toujours exact.
- Aucune mention de la conformité à l'exportation, de `ITSAppUses…` ou du chiffrement dans les README et `.md` hors vault.
- CLAUDE.md : seul celui de la racine (import du tronc). Rien à mettre à jour.

## Remarques (⚠️, non bloquantes, pas de nouveau tour)

- **R1 — Robustesse de `describeErrors` sur une charge malformée.** Si une valeur de `associatedErrors` n'est pas un tableau (`listObjet`), ou si un élément vaut `null` (`itemNull`), la fonction lève une `TypeError` à l'intérieur de `request`. L'échec reste fermé (on s'arrête quand même), mais le statut HTTP et le texte d'Apple sont perdus. Le format documenté par Apple n'est pas concerné, donc il n'y a pas de test rouge sur un cas réel. Piste : `Array.isArray(list) ? list : []` et `a?.source`.
- **R2 — Un cas cosmétique et une couverture d'intégration absente.** Une erreur sans `title` ni `detail` produit un segment vide (`" | r : ?"`). Le message n'a pas de borne de longueur quand Apple renvoie beaucoup d'`associatedErrors`. Aucun test ne vérifie le passage par `makeClient` : le test ne porte que sur `describeErrors`. La sonde ci-dessus prouve ce passage, mais elle est hors dépôt.
- **R3 — Docs (facultatif).** `scripts/release/README.md` pourrait dire que la conformité à l'exportation est déclarée dans `Info.plist` (`ITSAppUsesNonExemptEncryption = false`). Cette déclaration devra être revue si un vrai chiffrement de données entre un jour dans l'app.

## Verdict

**GO.** Aucune réserve n'est prouvée par un test rouge. Aucun axe N3 n'est bloquant : budget 0 BLOQUE, aucun chiffrement non exempté (seulement SHA256 pour nommer des fichiers de cache, et aucune dépendance tierce).
