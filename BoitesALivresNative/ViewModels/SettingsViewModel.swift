import Foundation
import UserNotifications
import Observation

// MARK: - Settings View Model

@MainActor @Observable
final class SettingsViewModel {
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    var pushToken: String? = nil
    var submissions: [PhotoSubmission] = []
    var deletionRequests: [DeletionRequestRecord] = []
    var showCacheClearAlert = false
    var cacheClearDone = false

    // Load notification status, device push token, photo submissions and deletion requests on view appear
    func onAppear() async {
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
        pushToken = NotificationService.shared.getPushToken()
        async let subs = PhotoService.shared.loadSubmissions()
        async let dels = (try? await SupabaseService.shared.fetchMyDeletionRequests()) ?? []
        submissions = await subs
        deletionRequests = await dels
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
