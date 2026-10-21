# Journal des modifications

Toutes les évolutions notables de l'app iOS Boîtes à livres sont consignées ici.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et la numérotation suit
[SemVer](https://semver.org/lang/fr/) : X.Y.Z, Z = correctifs seuls, Y = nouveautés visibles,
X = refonte. Le numéro de build augmente de 1 à chaque envoi en store. Chaque publication reçoit
une entrée ici, un tag `vX.Y.Z` et une release GitHub.

## [1.3.0] - non publiée

Build 13. Contenu depuis la 1.2.0 publiée (build 5, commit `9783299`).

### Build 19

- Ajout de boîte : le repère est une épingle fixe au centre de la carte, on glisse la carte pour placer
  la boîte. « Replacer » rouvre la carte sur le point déjà posé, sans recentrage automatique sur le GPS.

### Build 18

- Ajout de boîte : le champ note reste visible au-dessus du clavier, à hauteur fixe (5 lignes, défilement
  interne). Un seul saut de ligne d'affilée dans la note, à la saisie comme au collage. Bouton OK au-dessus
  du clavier (#38).
- Ajout de boîte : création possible à 50 m de précision GPS ou mieux (la localisation reste à 10 m) (#38).

### Build 17

- Localisation : un seul écran. La carte s'ouvre centrée sur la boîte ; laisse le repère sur la boîte
  et envoie, ou déplace la carte si elle est ailleurs. Le déplacement est limité à 100 m.
- Alerte près d'une boîte : activée par défaut, rayon de 100 m (la présence pour proposer une
  position reste à 50 m). Un désactivement explicite dans Réglages reste respecté.

### Build 16

- Mise à jour obligatoire : l'équipe fixe une version minimale. Si ta version de l'app est en
  dessous, un écran « Mise à jour nécessaire » bloque l'app jusqu'à la mise à jour (bouton vers
  l'App Store). La vérification a lieu au lancement et à chaque retour au premier plan. Si elle
  échoue (hors ligne, erreur), l'app reste utilisable. L'écran reste au-dessus de toute feuille
  ou fenêtre déjà ouverte.
- Signaler une suppression : le bouton n'est actif qu'à 100 m ou moins de la boîte. Au-delà, il
  est grisé avec un message. La photo reste à 100 m.

### Build 15

- Alerte de proximité : une alerte affichée compte comme vue. La boîte n'est plus signalée pendant
  30 jours, même si la notification est ignorée ou balayée.

### Build 14

- Localisation : la précision et la position se mettent à jour en temps réel pendant l'écran
  « La boîte est-elle bien ici ? ». Entre 10 et 50 m, tu peux placer le repère toi-même ; au-delà de
  50 m, l'envoi est refusé avec un message clair.
- Après l'envoi, l'écran « Merci ! » est centré et propose d'ajouter une photo.
- Alerte de proximité : déjà à côté d'une boîte au moment de l'activation, l'alerte part aussi.
  Réglages › Localisation › « Diagnostic des alertes » affiche un journal local (200 lignes au plus).
- Nouvelle boîte : photo obligatoire, prise sur place (appareil photo uniquement), et présence à 50 m
  au plus du point proposé, avec un GPS précis à 10 m. La position n'est jamais envoyée au serveur.

### Ajouté

- Localisation d'une boîte : sur la fiche, le bouton « Localisation » (actif à 50 m ou moins de la
  boîte) permet de confirmer qu'elle est là, ou de placer le repère sur la carte. La précision GPS doit
  être de 10 m au plus. Rien ne change sur la carte avant la validation par un administrateur.
- Alerte près d'une boîte (Réglages › Localisation, désactivée par défaut) : un rappel « La boîte
  est-elle bien ici ? » quand tu passes à moins de 50 m, même application fermée. Ta position ne quitte
  pas ton téléphone. Après « Plus tard », la même boîte n'alerte plus pendant 30 jours.
- « Mes soumissions » affiche tes propositions de localisation, avec leur statut.
- Avertissement « Aucune personne ne doit apparaître sur la photo. Les photos avec des personnes
  sont refusées. » avant la prise ou le choix d'une photo : encadré dans la feuille « Ajouter une
  photo » d'une boîte existante, et message de la boîte de dialogue photo à la création d'une
  boîte. Texte localisé FR/EN. (#4, commit `afb54ba`, PR #7)

### Corrigé

- Avis : le nombre estimé de livres se saisit au clavier numérique, avec un bouton OK ; les boutons
  − / + restent synchronisés (#21).
- Fiche : l'aperçu affiche toutes les photos de la boîte, dans le même ordre que la visionneuse. Une
  erreur réseau passagère ne retire plus une photo de l'aperçu (#22).
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
- La migration `supabase/migrations/20261019120000_location_updates.sql` doit être appliquée en base
  avant la mise en ligne du build 13 (table `location_updates`, RPC `my_location_updates`). Sans elle,
  le bouton « Localisation » envoie un message d'indisponibilité et « Mes soumissions » n'affiche pas
  les propositions de localisation.


### Notes App Store (FR, ≤ 4000 car.)

```
Nouveautés de la version 1.3.0

• Avant de prendre ou de choisir une photo de boîte à livres, l'app vous rappelle qu'aucune personne ne doit apparaître sur la photo. Les photos montrant des personnes sont refusées.

• « Mes soumissions » et « Mes demandes de suppression » n'affichent plus que ce que vous avez envoyé depuis votre téléphone. Vos envois restent privés.

• Localisation : sur la fiche d'une boîte, confirmez qu'elle est bien là ou placez-la sur la carte. Votre position reste sur votre téléphone ; un administrateur valide chaque proposition avant tout changement.

• Alerte près d'une boîte (Réglages) : un rappel « La boîte est-elle bien ici ? » quand vous passez à moins de 50 m, même application fermée. Désactivé par défaut.

• Les photos des boîtes affichent désormais uniquement les photos validées. Les photos en attente de validation ne sont plus visibles par tous.

• « Mes soumissions » affiche désormais le motif de modération d'une photo refusée, et des dates lisibles.

• Réglages affiche désormais la version et le numéro de build de l'app.

• Carte : passer d'une boîte à une autre est désormais fluide. La fiche reste à sa place et affiche directement la nouvelle boîte.

Merci d'alimenter la carte des boîtes à livres !
```

## [1.2.0] - publiée (date de mise en ligne non consignée)

Build 5, en ligne sur l'App Store ; commit de version du 2026-06-02 (`9783299`). Avis de la
communauté, garde géographique de 100 m, liste « Mes soumissions » unifiée.
