import Foundation
import Observation

@MainActor @Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()
    var pendingBoxId: Int?
}
