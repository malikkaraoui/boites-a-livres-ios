# Publication App Store sans passer par le site

Deux commandes `make`, aucune dépendance ajoutée (Node natif + `xcodebuild`).

| Commande | Effet |
|---|---|
| `make release-check` | **Lecture seule.** Vérifie que la clé fonctionne, affiche la version en ligne, ses états et les derniers builds reçus. Code de sortie ≠ 0 si Apple refuse la clé. |
| `make release CONFIRMER=OK-APPLE` | **Publie.** Sans `CONFIRMER=OK-APPLE` exactement, rien ne démarre. |

Ne lancer `make release` qu'après le « OK Apple » explicite du fondateur.

## Prérequis

- Clé API App Store Connect (rôle « App Manager » ou « Admin ») : fichier `AuthKey_<KEY_ID>.p8`, hors dépôt, `chmod 600`.
- `~/.appstoreconnect/config.env` (modèle : `scripts/release/config.env.example`) :
  - `ASC_KEY_ID` et `ASC_ISSUER_ID` (identifiants non secrets) ;
  - `ASC_KEY_PATH` : chemin du `.p8`.
- Le `.gitignore` exclut `*.p8` et `config.env`. Ne jamais afficher ni committer le contenu de la clé ni un jeton signé.

## Ce que fait `make release`, étape par étape

0. **Préflight** (lecture seule, **exécuté en premier**, avant toute archive ou envoi). Un seul échec = arrêt immédiat, message clair, code ≠ 0, rien n'est lancé :
   1. la clé est acceptée par Apple (un GET réel sur `/v1/apps`) ;
   2. aucune version de l'app n'est dans un état d'attente ou de revue (`WAITING_FOR_REVIEW`, `IN_REVIEW`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_APP_STORE`, `PENDING_APPLE_RELEASE`) ; la liste des versions est lue **en entier**, toutes les pages ;
   3. la version locale (`MARKETING_VERSION`) est supérieure à la version en ligne, le build (`CURRENT_PROJECT_VERSION`) supérieur au dernier build reçu, et aucune autre version en préparation ne porte un numéro différent ;
   4. `release-notes/fr-FR.txt` est présent, non vide et ≤ 4000 caractères.

   `make release-check` affiche ce même verdict (il ne fait que des GET). Le préflight ne lit pas la clé `.p8` au-delà de son chargement et n'affiche aucun jeton.
1. **Archive** Release (`xcodebuild archive`, authentification par la clé).
2. **Envoi** du build (`xcodebuild -exportArchive`, `destination upload`, options dans `scripts/release/ExportOptions.plist`).
3. **Attente** du traitement du build par Apple : sondage borné (40 essais, 30 s d'intervalle), arrêt net si Apple le refuse.
4. **Version** : réutilise la version en préparation de même numéro, ou en crée une.
5. **Nouveautés** : texte `release-notes/fr-FR.txt` (≤ 4000 caractères), puis rattachement du build à la version.
6. **Soumission** à la revue (`reviewSubmissions`).

Toute erreur arrête tout et affiche le message d'Apple, avec l'étape où l'on s'est arrêté. Un état partiel est alors possible : vérifier App Store Connect avant de relancer.

## Tests hors ligne

```sh
node --test scripts/release/asc.test.mjs
```

Les tests utilisent une clé éphémère et un `fetch` factice : aucun envoi, aucune lecture de la vraie clé.
