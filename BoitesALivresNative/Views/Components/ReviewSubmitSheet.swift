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
    @State private var bookCountText = "10"
    @State private var includeBookCount = true
    @State private var submitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil
    @State private var userLocation: CLLocation? = nil
    @State private var locationError: String? = nil
    @FocusState private var commentFocused: Bool
    @FocusState private var bookCountFocused: Bool
    @State private var feedback = MissingFeedback<SubmitRequirements.Review>()

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

    // Source unique des manques (F01 M0045) ; canSubmit n'en garde que la couleur et l'envoi
    private var missingRequirements: [SubmitRequirements.Review] {
        SubmitRequirements.review(
            hasCondition: condition != nil,
            commentFilled: !comment.trimmingCharacters(in: .whitespaces).isEmpty,
            withinRange: isWithinRange
        )
    }

    private var canSubmit: Bool { missingRequirements.isEmpty && !submitting }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    handle
                    header
                    proximityBanner
                        .id("proximity")
                        .missingHighlight(tick: feedback.tick(for: .proximity))
                    conditionSection
                    bookCountSection
                    authorSection
                    commentSection
                        .id("comment")
                    if let err = errorMessage { errorRow(err) }
                    Spacer().frame(height: 16)
                    // Boutons collés au-dessus du clavier quand le commentaire a le focus (M0044)
                    if !commentFocused {
                        submitButton(proxy)
                        cancelButton
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if commentFocused {
                    VStack(spacing: 0) {
                        submitButton(proxy)
                        cancelButton
                    }
                    .padding(.top, 8)
                    .background(Color(.systemBackground))
                }
            }
            // Le champ commentaire entier (compteur compris) défile au-dessus du clavier (M0044)
            .onChange(of: commentFocused) { _, focused in
                guard focused else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    withAnimation { proxy.scrollTo("comment", anchor: .bottom) }
                }
            }
            // Bouton OK au-dessus du clavier numérique du nombre de livres (#21)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if bookCountFocused {
                        Spacer()
                        Button("OK") { bookCountFocused = false }
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        // Le nombre et son champ restent synchronisés, avec − / + et la saisie au clavier (#21)
        .onChange(of: bookCount) { _, value in
            bookCountText = String(value)
        }
        .onChange(of: bookCountText) { _, text in
            let value = BookCountInput.parse(text, previous: bookCount)
            bookCount = value
            if !text.isEmpty && Int(text) != value {
                bookCountText = String(value)
            }
        }
        .onChange(of: bookCountFocused) { _, focused in
            // Sortie du champ : valeur vide ou hors bornes ramenée à la valeur effective
            if !focused { bookCountText = String(bookCount) }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        // Succès d'envoi en pleine page, comme après une photo (F01 M0046).
        // Le glissement ne ferme pas la feuille avant « Fermer » : onSubmitted() doit toujours partir.
        .interactiveDismissDisabled(showSuccess)
        .overlay {
            if showSuccess {
                SubmissionSuccessView(
                    title: "Avis envoyé",
                    message: "Merci ! Ton avis sera publié après validation par un administrateur.",
                    primaryAction: { onSubmitted(); dismiss() }
                )
            }
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
                .missingHighlight(tick: feedback.tick(for: .condition))
            if let hint = feedback.message(for: .condition) {
                flashHint(hint)
            }
        }
        .id("condition")
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
                    Stepper("", value: $bookCount, in: BookCountInput.range).labelsHidden()
                    Spacer()
                    TextField("0", text: $bookCountText)
                        .keyboardType(.numberPad)
                        .focused($bookCountFocused)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(green)
                        .frame(maxWidth: 120)
                        .accessibilityLabel("Nombre estimé de livres")
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
                    // Saisie et collage : un seul saut de ligne d'affilée, puis limite de caractères (M0044)
                    .onChange(of: comment) { _, new in
                        let clean = String(NoteText.limitLineBreaks(new).prefix(maxComment))
                        if clean != new { comment = clean }
                    }
                Text("\(comment.count)/\(maxComment)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .missingHighlight(tick: feedback.tick(for: .comment))
            if let hint = feedback.message(for: .comment) {
                flashHint(hint)
            }
        }
        .padding(.horizontal, 20)
    }

    // Message court affiché sous l'élément manquant pendant le clignotement (F01 M0045)
    private func flashHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // Grisé mais touchable : toucher sans manque envoie ; avec un manque, défile, clignote et message (F01 M0045)
    private func submitButton(_ proxy: ScrollViewProxy) -> some View {
        Button {
            submitTapped(proxy)
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

    private func submitTapped(_ proxy: ScrollViewProxy) {
        guard !submitting else { return }
        guard let first = missingRequirements.first else {
            // Clavier fermé avant l'envoi : la page de remerciement s'affiche sans lui (F01 M0047)
            dismissKeyboard()
            submit()
            return
        }
        // Manque non textuel : le clavier ne cache pas l'élément qui clignote (F01 M0047)
        if first != .comment { dismissKeyboard() }
        errorHaptic()
        withAnimation { proxy.scrollTo(first.anchor, anchor: .center) }
        feedback.flash(first, message: first.hint)
    }

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
