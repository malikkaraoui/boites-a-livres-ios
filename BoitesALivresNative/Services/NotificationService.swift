import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let tokenKey = "devicePushToken"

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func savePushToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func getPushToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
}
