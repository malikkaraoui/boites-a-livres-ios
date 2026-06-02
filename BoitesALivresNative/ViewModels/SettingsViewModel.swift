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
    var myReviews: [BoxReview] = []
    var myBoxSubmissions: [BoxSubmissionRecord] = []
    var showCacheClearAlert = false
    var cacheClearDone = false

    // Load notification status, device push token, photo submissions, deletion requests,
    // mes avis et mes soumissions de nouvelles boîtes — tout en parallèle.
    func onAppear() async {
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
        pushToken = NotificationService.shared.getPushToken()
        async let subs = PhotoService.shared.loadSubmissions()
        async let dels = (try? await SupabaseService.shared.fetchMyDeletionRequests()) ?? []
        async let revs = (try? await SupabaseService.shared.fetchMyReviews()) ?? []
        async let boxes = (try? await SupabaseService.shared.fetchMyBoxSubmissions()) ?? []
        submissions = await subs
        deletionRequests = await dels
        myReviews = await revs
        myBoxSubmissions = await boxes
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
