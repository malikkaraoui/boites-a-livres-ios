import SwiftUI
import UIKit

@main
struct BoitesALivresApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Lancer les permissions en parallèle, sans bloquer l'UI
                    Task.detached(priority: .background) {
                        // Petit délai pour laisser la map demander la localisation en premier
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
}
