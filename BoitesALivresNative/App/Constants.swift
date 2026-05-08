import CoreLocation
import Foundation

enum Constants {
    static let supabaseURL = "https://tszxcbsdjdtecoikxuwu.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzenhjYnNkamR0ZWNvaWt4dXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5NzE3NTksImV4cCI6MjA5MzU0Nzc1OX0.KQSz_k6XPl2CpvIrCK0aKlmZuhqGZudFdurA3YCxJoY"
    static let defaultRadiusKm: Double = 5
    static let radiusOptionsKm: [Double] = [5, 10, 30]
    static let nearbyLimit = 15
    static let listPageSize = 50
    static let maxPhotosPerBox = 5
    static let defaultLocation = CLLocationCoordinate2D(latitude: 45.9245224, longitude: 6.1537557)
}
