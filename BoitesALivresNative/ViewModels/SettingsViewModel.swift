import Foundation
import UserNotifications
import Observation

// MARK: - Settings View Model

@MainActor @Observable
final class SettingsViewModel {
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    var pushToken: String? = nil
    var submissions: [PhotoSubmission] = []
    var showCacheClearAlert = false
    var cacheClearDone = false

    // Load notification status, device push token, and photo submissions on view appear
    func onAppear() async {
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
        pushToken = NotificationService.shared.getPushToken()
        submissions = await PhotoService.shared.loadSubmissions()
    }

    // Request notification permission and refresh status
    func requestNotifications() async {
        _ = await NotificationService.shared.requestPermission()
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
    }

    // Clear both disk and memory caches; show confirmation feedback for 2 seconds
    func clearCache() async {
        await LocalCacheService.shared.clear()
        ImageCacheService.shared.clear()
        cacheClearDone = true
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        cacheClearDone = false
    }
}
