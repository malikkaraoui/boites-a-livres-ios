import UIKit
import UserNotifications

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Configure notification center to handle foreground notifications
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Store APNs device token for backend push notification delivery
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
        NotificationService.shared.savePushToken(tokenHex)
        print("[APNs] Device token enregistré : \(tokenHex.prefix(16))…")
    }

    // Log APNs registration failure for debugging
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Échec enregistrement : \(error.localizedDescription)")
    }

    // Show notification in foreground with banner and sound
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle notification tap: extract photo-approved event and route to detail view
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String

        if type == "photo-approved", let boxId = userInfo["boxId"] as? Int {
            Task { @MainActor in
                DeepLinkRouter.shared.pendingBoxId = boxId
            }
        }
        completionHandler()
    }
}
