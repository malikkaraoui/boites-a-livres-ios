import SwiftUI
import CoreLocation

// MARK: - Condition styling

// Couleur et libellé localisé associés à un état de boîte.
// Réutilisé par ReviewSubmitSheet, DetailView (liste d'avis), et MapScreen (pin).
enum ConditionStyle {
    static func color(for condition: BoxReview.Condition?) -> Color {
        switch condition {
        case .bon: return Color(red: 0.102, green: 0.718, blue: 0.608)  // vert teal (couleur primaire)
        case .moyen: return Color(red: 0.95, green: 0.62, blue: 0.07)   // orange chaleureux
        case .mauvais: return Color(red: 0.86, green: 0.21, blue: 0.27) // rouge
        case .none: return Color(.systemGray)
        }
    }

    static func label(for condition: BoxReview.Condition) -> LocalizedStringKey {
        switch condition {
        case .bon: return "Bon"
        case .moyen: return "Moyen"
        case .mauvais: return "Mauvais"
        }
    }

    static func icon(for condition: BoxReview.Condition) -> String {
        switch condition {
        case .bon: return "checkmark.seal.fill"
        case .moyen: return "exclamationmark.triangle.fill"
        case .mauvais: return "xmark.octagon.fill"
        }
    }
}

// MARK: - ConditionBadge

struct ConditionBadge: View {
    let condition: BoxReview.Condition
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: ConditionStyle.icon(for: condition))
                .font(.system(size: compact ? 10 : 11, weight: .bold))
            Text(ConditionStyle.label(for: condition))
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(ConditionStyle.color(for: condition))
        .clipShape(Capsule())
    }
}

// MARK: - ConditionPicker

struct ConditionPicker: View {
    @Binding var selection: BoxReview.Condition?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BoxReview.Condition.allCases, id: \.self) { c in
                let isSelected = selection == c
                let color = ConditionStyle.color(for: c)
                Button {
                    mediumHaptic()
                    selection = c
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: ConditionStyle.icon(for: c))
                            .font(.system(size: 18, weight: .bold))
                        Text(ConditionStyle.label(for: c))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSelected ? color : color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

// MARK: - ReviewSubmitSheet

struct ReviewSubmitSheet: View {
    let boxId: Int
    let boxCoordinate: CLLocationCoordinate2D
    var onSubmitted: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var condition: BoxReview.Condition? = nil
    @State private var authorName = ""
    @State private var comment = ""
    @State private var bookCount: Int = 10
    @State private var includeBookCount = true
    @State private var submitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil
    @State private var userLocation: CLLocation? = nil
    @State private var locationError: String? = nil
    @FocusState private var commentFocused: Bool

    private let maxComment = 150
    private let maxName = 30
    private let maxDistanceMeters: CLLocationDistance = 100
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    private var distanceMeters: CLLocationDistance? {
        guard let user = userLocation else { return nil }
        let target = CLLocation(latitude: boxCoordinate.latitude, longitude: boxCoordinate.longitude)
        return user.distance(from: target)
    }

    private var isWithinRange: Bool {
        guard let d = distanceMeters else { return false }
        return d <= maxDistanceMeters
    }

    private var canSubmit: Bool {
        condition != nil
        && !comment.trimmingCharacters(in: .whitespaces).isEmpty
        && !submitting
        && isWithinRange
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                handle
                header
                proximityBanner
                conditionSection
                bookCountSection
                authorSection
                commentSection
                if let err = errorMessage { errorRow(err) }
                Spacer().frame(height: 16)
                submitButton
                cancelButton
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .alert("Avis envoyé", isPresented: $showSuccess) {
            Button("OK") { onSubmitted(); dismiss() }
        } message: {
            Text("Merci ! Ton avis sera publié après validation par un administrateur.")
        }
        .task {
            await refreshUserLocation()
        }
    }

    private func refreshUserLocation() async {
        LocationService.shared.requestAuthorization()
        LocationService.shared.startUpdatingIfAuthorized()
        if let cached = LocationService.shared.currentLocation {
            userLocation = cached
        }
        do {
            let fresh = try await LocationService.shared.requestCurrentLocation()
            userLocation = fresh
            locationError = nil
        } catch {
            if userLocation == nil {
                locationError = NSLocalizedString("Position introuvable. Activez la localisation pour pouvoir noter cette boîte.", comment: "")
            }
        }
    }

    @ViewBuilder
    private var proximityBanner: some View {
        if let err = locationError {
            proximityRow(icon: "location.slash.fill", color: .orange, text: err)
        } else if let d = distanceMeters {
            if isWithinRange {
                proximityRow(
                    icon: "checkmark.circle.fill",
                    color: green,
                    text: String(format: NSLocalizedString("Vous êtes à %d m de la boîte ✓", comment: ""), Int(d.rounded()))
                )
            } else {
                proximityRow(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    text: String(format: NSLocalizedString("Trop loin pour noter — vous êtes à %@ de la boîte. Approchez-vous à moins de 100 m.", comment: ""), formattedDistance(d))
                )
            }
        } else {
            proximityRow(icon: "location.circle", color: .secondary, text: NSLocalizedString("Localisation en cours…", comment: ""))
        }
    }

    private func proximityRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters.rounded())) m"
    }

    // MARK: - Sections

    private var handle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 18)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Donner mon avis")
                .font(.system(size: 18, weight: .bold))
            Text("Boîte #\(boxId)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 20)
    }

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("État de la boîte")
            ConditionPicker(selection: $condition)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private var bookCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("Nombre estimé de livres")
                Spacer()
                Toggle("", isOn: $includeBookCount).labelsHidden().tint(green)
            }
            if includeBookCount {
                HStack {
                    Stepper("", value: $bookCount, in: 0...200).labelsHidden()
                    Spacer()
                    Text("\(bookCount)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(green)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private var authorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Votre nom (facultatif)")
            TextField("Anonyme", text: $authorName)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: authorName) { _, new in
                    if new.count > maxName { authorName = String(new.prefix(maxName)) }
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Commentaire")
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $comment)
                    .focused($commentFocused)
                    .font(.system(size: 15))
                    .frame(height: 120)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(commentFocused ? green.opacity(0.5) : Color(.systemGray4), lineWidth: 1)
                    )
                    .onChange(of: comment) { _, new in
                        if new.count > maxComment { comment = String(new.prefix(maxComment)) }
                    }
                Text("\(comment.count)/\(maxComment)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 20)
    }

    private func errorRow(_ err: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
            Text(err).font(.system(size: 12))
        }
        .foregroundStyle(.orange)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack(spacing: 8) {
                if submitting { ProgressView().tint(.white).scaleEffect(0.85) }
                Text(submitting ? "Envoi…" : "Envoyer mon avis")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSubmit ? green : green.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit)
        .padding(.horizontal, 20)
    }

    private var cancelButton: some View {
        Button("Annuler") { dismiss() }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.vertical, 14)
    }

    private func sectionLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    // MARK: - Submit

    private func submit() {
        guard let cond = condition else { return }
        guard isWithinRange else {
            errorMessage = NSLocalizedString("Vous devez être à moins de 100 m de la boîte pour la noter.", comment: "")
            return
        }
        submitting = true
        errorMessage = nil
        Task {
            do {
                try await SupabaseService.shared.insertReview(
                    boxId: boxId,
                    authorName: authorName,
                    comment: comment,
                    condition: cond,
                    bookCount: includeBookCount ? bookCount : nil
                )
                await MainActor.run { showSuccess = true; submitting = false }
            } catch let error as SupabaseError {
                await MainActor.run {
                    submitting = false
                    if case .httpError(let code, let body) = error {
                        if code == 409 || body.contains("CADENCE_EXCEEDED") {
                            errorMessage = NSLocalizedString("Vous avez déjà laissé un avis cette semaine sur cette boîte", comment: "")
                        } else {
                            errorMessage = NSLocalizedString("Une erreur est survenue. Réessaie plus tard.", comment: "")
                        }
                    } else {
                        errorMessage = NSLocalizedString("Une erreur est survenue. Réessaie plus tard.", comment: "")
                    }
                }
            } catch {
                await MainActor.run {
                    submitting = false
                    errorMessage = NSLocalizedString("Une erreur est survenue. Réessaie plus tard.", comment: "")
                }
            }
        }
    }
}
