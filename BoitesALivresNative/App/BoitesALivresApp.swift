import SwiftUI
import UIKit

// MARK: - App Entry Point

@main
struct BoitesALivresApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("colorSchemeIndex") private var colorSchemeIndex = 0
    @AppStorage("textSizeIndex") private var textSizeIndex = 0

    init() {
        // Purge any previously forced language — let iOS use system language
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
    }

    var body: some Scene {
        WindowGroup {
            // Le LaunchScreen iOS natif (Info.plist → UILaunchScreen.LaunchBackground)
            // assure déjà la transition visuelle au démarrage. Pas de splash SwiftUI
            // pour éviter de bloquer le first-frame derrière l'init de MapKit.
            ContentView()
                .preferredColorScheme(resolvedColorScheme)
                .environment(\.dynamicTypeSize, resolvedTypeSize)
                .task {
                    Task.detached(priority: .background) {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        let granted = await NotificationService.shared.requestPermission()
                        if granted {
                            await MainActor.run {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                }
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemeIndex {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private var resolvedTypeSize: DynamicTypeSize {
        switch textSizeIndex {
        case 1: return .xxLarge
        case 2: return .accessibility1
        default: return .large
        }
    }
}
