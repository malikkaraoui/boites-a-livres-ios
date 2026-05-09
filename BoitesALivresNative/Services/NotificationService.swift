import Foundation
import UserNotifications

// MARK: - Notification Service

final class NotificationService {
    static let shared = NotificationService()
    private let tokenKey = "devicePushToken"

    // Request user permission for alert, badge, and sound notifications
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // Fetch current notification authorization status from system
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // Store APNs device token in UserDefaults for backend submission with photo uploads
    func savePushToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    // Retrieve saved APNs device token for use in photo submission tracking
    func getPushToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
}
