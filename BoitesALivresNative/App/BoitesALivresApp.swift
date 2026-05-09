import SwiftUI
import UIKit

// MARK: - App Entry Point

@main
struct BoitesALivresApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .task {
                        // Request notification permissions in background after location; register APNs if granted
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

                if showSplash {
                    SplashView(isVisible: $showSplash)
                        .transition(.opacity)
                }
            }
        }
    }
}
