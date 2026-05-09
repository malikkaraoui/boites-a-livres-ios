import Foundation
import Observation

// MARK: - Deep Link Router

@MainActor @Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    // Box ID to navigate to when deep link is received; observed for navigation stack updates
    var pendingBoxId: Int?
}
