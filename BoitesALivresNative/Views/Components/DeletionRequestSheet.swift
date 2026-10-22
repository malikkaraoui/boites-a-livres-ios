import SwiftUI

struct DeletionRequestSheet: View {
    let boxId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var submitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil
    @FocusState private var focused: Bool
    @State private var feedback = MissingFeedback<SubmitRequirements.Deletion>()

    private let maxChars = 100

    // Source unique des manques (F01 M0045) ; canSubmit n'en garde que la couleur et l'envoi
    private var missingRequirements: [SubmitRequirements.Deletion] {
        SubmitRequirements.deletion(reasonFilled: !reason.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 20)

                    Text("Demander la suppression")
                        .font(.system(size: 17, weight: .bold))
                        .padding(.bottom, 10)

                    Text("Cette boîte sera supprimée uniquement après validation par un administrateur. Explique brièvement pourquoi.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    ZStack(alignment: .bottomTrailing) {
                        TextEditor(text: $reason)
                            .focused($focused)
                            .font(.system(size: 15))
                            .frame(height: 100)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focused ? Color.red.opacity(0.4) : Color(.systemGray4), lineWidth: 1)
                            )
                            // Saisie et collage : un seul saut de ligne d'affilée, puis limite de caractères (M0044)
                            .onChange(of: reason) { _, new in
                                let clean = String(NoteText.limitLineBreaks(new).prefix(maxChars))
                                if clean != new { reason = clean }
                            }

                        Text("\(reason.count)/\(maxChars)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                    .missingHighlight(tick: feedback.tick(for: .reason))
                    .padding(.horizontal, 20)
                    .id("reason")

                    if reason.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("La raison est obligatoire")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }
                    if let err = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(err)
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }

                    Spacer().frame(height: 20)

                    // Boutons collés au-dessus du clavier quand la raison a le focus (M0044)
                    if !focused {
                        submitButton(proxy)
                        cancelButton
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if focused {
                    VStack(spacing: 0) {
                        submitButton(proxy)
                        cancelButton
                    }
                    .padding(.top, 8)
                    .background(Color(.systemBackground))
                }
            }
            // Le champ raison entier défile au-dessus du clavier (M0044)
            .onChange(of: focused) { _, isFocused in
                guard isFocused else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    withAnimation { proxy.scrollTo("reason", anchor: .bottom) }
                }
            }
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .onAppear { focused = true }
        // Succès d'envoi en pleine page, comme après une photo (F01 M0046).
        // Même blocage du glissement que l'ancienne alerte : la feuille se ferme par « Fermer ».
        .interactiveDismissDisabled(showSuccess)
        .overlay {
            if showSuccess {
                SubmissionSuccessView(
                    title: "Demande envoyée",
                    message: "Merci. Ta demande sera examinée par un administrateur avant toute action.",
                    primaryAction: { dismiss() }
                )
            }
        }
    }

    // Grisé mais touchable : toucher avec un manque défile, clignote et ne envoie rien (F01 M0045)
    private func submitButton(_ proxy: ScrollViewProxy) -> some View {
        Button {
            submitTapped(proxy)
        } label: {
            HStack(spacing: 8) {
                if submitting { ProgressView().tint(.white).scaleEffect(0.85) }
                Text(submitting ? "Envoi…" : "Envoyer la demande")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(missingRequirements.isEmpty ? Color.red : Color.red.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }

    private func submitTapped(_ proxy: ScrollViewProxy) {
        guard !submitting else { return }
        guard let first = missingRequirements.first else {
            // Clavier fermé avant l'envoi : la page de remerciement s'affiche sans lui (F01 M0047)
            dismissKeyboard()
            submit()
            return
        }
        errorHaptic()
        withAnimation { proxy.scrollTo(first.anchor, anchor: .center) }
        feedback.flash(first, message: first.hint)
    }

    private var cancelButton: some View {
        Button("Annuler") { dismiss() }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.vertical, 14)
    }

    private func submit() {
        submitting = true
        errorMessage = nil
        Task {
            do {
                try await SupabaseService.shared.submitDeletionRequest(boxId: boxId, reason: reason.trimmingCharacters(in: .whitespaces))
                await MainActor.run { showSuccess = true }
            } catch let error as SupabaseError {
                await MainActor.run {
                    submitting = false
                    if case .httpError(let code, let body) = error, code == 409 || body.contains("deletion_requests_pending_unique") {
                        errorMessage = "Tu as déjà une demande en attente pour cette boîte. Attends la décision de l'administrateur."
                    } else {
                        errorMessage = "Une erreur est survenue. Réessaie plus tard."
                    }
                }
            } catch {
                await MainActor.run {
                    submitting = false
                    errorMessage = "Une erreur est survenue. Réessaie plus tard."
                }
            }
        }
    }
}
