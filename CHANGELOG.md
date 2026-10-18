# Journal des modifications

Toutes les évolutions notables de l'app iOS Boîtes à livres sont consignées ici.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et la numérotation suit
[SemVer](https://semver.org/lang/fr/) : X.Y.Z, Z = correctifs seuls, Y = nouveautés visibles,
X = refonte. Le numéro de build augmente de 1 à chaque envoi en store. Chaque publication reçoit
une entrée ici, un tag `vX.Y.Z` et une release GitHub.

## [1.3.0] - non publiée

Build 12. Contenu depuis la 1.2.0 publiée (build 5, commit `9783299`).

### Ajouté

- Avertissement « Aucune personne ne doit apparaître sur la photo. Les photos avec des personnes
  sont refusées. » avant la prise ou le choix d'une photo : encadré dans la feuille « Ajouter une
  photo » d'une boîte existante, et message de la boîte de dialogue photo à la création d'une
  boîte. Texte localisé FR/EN. (#4, commit `afb54ba`, PR #7)

### Corrigé

- « Mes soumissions » photo : la liste ne montre plus que les soumissions de l'appareil. Elle passe
  par la RPC `my_photo_submissions`, cloisonnée par jeton d'appareil, au lieu d'une lecture directe
  de la table. (#2, commit `ef324ee`, PR #7)
- « Mes demandes de suppression » : même cloisonnement par jeton d'appareil, via la RPC
  `my_deletion_requests`. Si la RPC est absente ou en erreur, la liste est vide. (#6, commit
  `aff63ab`, PR #10)
- Photos d'une boîte : le carrousel n'affiche plus que les photos validées. Les photos en attente de
  modération ne sont plus montrées au public. Une photo qui ne se charge pas est retirée de
  l'affichage, et la limite de 3 photos compte les photos validées.
- Aperçu de la carte : quand la photo d'une boîte ne se charge plus, l'aperçu essaie les photos
  validées suivantes au lieu de disparaître. Il ne se masque que si aucune photo ne s'affiche.
- « Mes soumissions » : le motif de modération d'une photo (ex. refus) s'affiche sous la ligne,
  préfixé « Motif : » (FR) / « Reason: » (EN). Rien si le motif est vide.
- « Mes soumissions » : la date n'apparaît plus brute (« 2026-10-17T14:03:35.035649+00:00 ») mais
  en relatif court (« il y a 1 j »). Les fractions de seconde de 1 à 6 chiffres sont lues.
- Réglages : le numéro de build est affiché à côté de la version (« v1.3.0 (11) »).
- Carte : toucher un autre point quand une fiche est ouverte n'ouvre plus la nouvelle fiche
  presque plein écran et floue. La fiche reste ouverte à sa petite hauteur et change de boîte sur
  place. Quand la photo d'une boîte se recharge depuis les photos validées, sa place reste réservée
  et la fiche ne saute plus. (build 12)

### Prérequis de publication

- Les migrations `supabase/migrations/20261014_my_photo_submissions.sql` et
  `supabase/migrations/20261015_my_deletion_requests.sql` doivent être appliquées en base avant la
  mise en ligne. Sans elles, les deux listes ci-dessus restent vides.

### Notes App Store (FR, ≤ 4000 car.)

```
Nouveautés de la version 1.3.0

• Avant de prendre ou de choisir une photo de boîte à livres, l'app vous rappelle qu'aucune personne ne doit apparaître sur la photo. Les photos montrant des personnes sont refusées.

• « Mes soumissions » et « Mes demandes de suppression » n'affichent plus que ce que vous avez envoyé depuis votre téléphone. Vos envois restent privés.

• Les photos des boîtes affichent désormais uniquement les photos validées. Les photos en attente de validation ne sont plus visibles par tous.

• « Mes soumissions » affiche désormais le motif de modération d'une photo refusée, et des dates lisibles.

• Réglages affiche désormais la version et le numéro de build de l'app.

• Carte : passer d'une boîte à une autre est désormais fluide. La fiche reste à sa place et affiche directement la nouvelle boîte.

Merci d'alimenter la carte des boîtes à livres !
```

## [1.2.0] - publiée (date de mise en ligne non consignée)

Build 5, en ligne sur l'App Store ; commit de version du 2026-06-02 (`9783299`). Avis de la
communauté, garde géographique de 100 m, liste « Mes soumissions » unifiée.
