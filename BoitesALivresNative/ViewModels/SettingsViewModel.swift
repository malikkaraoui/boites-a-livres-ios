import Foundation
import UserNotifications
import Observation

@MainActor @Observable
final class SettingsViewModel {
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    var pushToken: String? = nil
    var submissions: [PhotoSubmission] = []
    var showCacheClearAlert = false
    var cacheClearDone = false

    func onAppear() async {
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
        pushToken = NotificationService.shared.getPushToken()
        submissions = await PhotoService.shared.loadSubmissions()
    }

    func requestNotifications() async {
        _ = await NotificationService.shared.requestPermission()
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
    }

    func clearCache() async {
        await LocalCacheService.shared.clear()
        ImageCacheService.shared.clear()
        cacheClearDone = true
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        cacheClearDone = false
    }
}
