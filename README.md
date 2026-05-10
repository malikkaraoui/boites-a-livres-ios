# Boîtes à Livres — iOS

Application iOS native pour trouver les boîtes à livres (little free libraries) partout en France.

Données issues de [boites-a-livres.fr](https://www.boites-a-livres.fr).

---

## Stack

| Composant | Technologie |
|---|---|
| UI | SwiftUI |
| Carte | MapKit |
| Backend | Supabase (PostgreSQL + Storage + Edge Functions) |
| Cache local | UserDefaults + NSCache (images) |
| Notifications push | APNs via Supabase |
| Localisation | `fr.lproj` + `en.lproj` (FR/EN automatique) |

## Fonctionnalités

- **Carte** — boîtes à livres géolocalisées avec filtre de rayon (5/10/20/50 km), marqueurs verts, style de carte paramétrable (standard / satellite / hybride)
- **Liste** — liste triée par distance, pagination, filtre photo
- **Détail** — coordonnées GPS (décimal/DMS), ouverture dans Plans, carousel photo plein écran, ajout de photo (appareil photo ou bibliothèque)
- **Réglages** — thème (clair/sombre/auto), taille de texte, unités km/miles, notifications push, partage, notation App Store, gestion du cache
- **Localisation** — 100 % français quand l'iPhone est en français, 100 % anglais sinon
- **Deep links** — navigation directe vers une boîte depuis une notification ou un lien externe
- **Mode sombre** — toutes les vues adaptées (pas de fond blanc codé en dur)

## Structure du projet

```
BoitesALivresNative/
├── App/
│   ├── BoitesALivresApp.swift     # Point d'entrée, splash, notifications
│   ├── ContentView.swift          # Tab bar flottante, gestion navigation
│   ├── MapScreen.swift            # Vue carte principale
│   ├── ListView.swift             # Vue liste + filtres
│   └── SettingsView.swift         # Réglages
├── Views/
│   ├── Components/
│   │   ├── BookBoxSheet.swift     # Sheet de prévisualisation sur la carte
│   │   ├── PhotoCarousel.swift    # Carousel photos
│   │   └── FullScreenPhotoViewer.swift
│   └── Detail/
│       └── DetailView.swift       # Vue détail d'une boîte
├── ViewModels/
│   ├── MapViewModel.swift
│   ├── ListViewModel.swift
│   ├── DetailViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── APIService.swift           # Appels Supabase
│   ├── LocationService.swift      # Géolocalisation
│   ├── LocalCacheService.swift    # Cache boîtes
│   ├── ImageCacheService.swift    # Cache images
│   ├── NotificationService.swift  # APNs
│   └── PhotoService.swift         # Upload photos
├── Models/
│   └── BookBox.swift
├── en.lproj/Localizable.strings
├── fr.lproj/Localizable.strings
└── App/Constants.swift
```

## Build

Prérequis : Xcode 16+, iOS 17+ cible.

```bash
# Ouvrir dans Xcode
open BoitesALivresNative.xcodeproj
```

Aucune dépendance externe (pas de SPM, pas de CocoaPods). Tout est natif Apple.

## Localisation

L'app détecte automatiquement la langue système. Pas de sélecteur manuel.

- `fr.lproj/Localizable.strings` — français (mapping identité)
- `en.lproj/Localizable.strings` — anglais

Pour ajouter une langue : créer `XX.lproj/Localizable.strings` + ajouter la région dans `project.pbxproj`.

## Contributeurs

Développé bénévolement par [Malik Karaoui](https://malikkaraoui.com).
