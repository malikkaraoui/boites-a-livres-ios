import SwiftUI

struct DeletionRequestSheet: View {
    let boxId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var submitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil
    @FocusState private var focused: Bool

    private let maxChars = 100
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    var body: some View {
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
                    .onChange(of: reason) { _, new in
                        if new.count > maxChars { reason = String(new.prefix(maxChars)) }
                    }

                Text("\(reason.count)/\(maxChars)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .padding(.horizontal, 20)

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

            Button {
                submit()
            } label: {
                HStack(spacing: 8) {
                    if submitting { ProgressView().tint(.white).scaleEffect(0.85) }
                    Text(submitting ? "Envoi…" : "Envoyer la demande")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(reason.trimmingCharacters(in: .whitespaces).isEmpty ? Color.red.opacity(0.3) : Color.red)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(reason.trimmingCharacters(in: .whitespaces).isEmpty || submitting)
            .padding(.horizontal, 20)

            Button("Annuler") { dismiss() }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.vertical, 14)
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .onAppear { focused = true }
        .alert("Demande envoyée", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Merci. Ta demande sera examinée par un administrateur avant toute action.")
        }
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
