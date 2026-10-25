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
    var myLocationUpdates: [LocationUpdateRecord] = []

    // Chargement en cours. Un second reload() pendant ce chargement attend celui-ci au lieu d'en lancer un autre.
    private var inFlight: Task<Void, Never>?

    // Recharge tout : à l'ouverture de l'onglet, au retour au premier plan, et au tirer-pour-rafraîchir.
    // Les valeurs affichées restent en place jusqu'à la réponse (pas de vidage pendant le chargement).
    func reload() async {
        if let inFlight {
            await inFlight.value
            return
        }
        let task = Task {
            await self.load()
            self.inFlight = nil
        }
        inFlight = task
        await task.value
    }

    // Load notification status, device push token, photo submissions, deletion requests,
    // mes avis et mes soumissions de nouvelles boîtes — tout en parallèle.
    private func load() async {
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
        pushToken = NotificationService.shared.getPushToken()
        async let subs = PhotoService.shared.loadSubmissions()
        async let dels = (try? await SupabaseService.shared.fetchMyDeletionRequests()) ?? []
        async let revs = (try? await SupabaseService.shared.fetchMyReviews()) ?? []
        async let boxes = (try? await SupabaseService.shared.fetchMyBoxSubmissions()) ?? []
        async let locs = (try? await SupabaseService.shared.fetchMyLocationUpdates()) ?? []
        submissions = await subs
        deletionRequests = await dels
        myReviews = await revs
        myBoxSubmissions = await boxes
        myLocationUpdates = await locs
    }

    // Request notification permission and refresh status
    func requestNotifications() async {
        _ = await NotificationService.shared.requestPermission()
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
    }
}
