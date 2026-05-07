import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @State private var vm = SettingsViewModel()

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)

    var body: some View {
        NavigationStack {
            List {
                // Notifications
                Section("Notifications") {
                    HStack {
                        Label("Statut", systemImage: "bell.fill")
                        Spacer()
                        Text(notifStatusLabel)
                            .font(.system(size: 13))
                            .foregroundStyle(notifStatusColor)
                    }

                    if let token = vm.pushToken {
                        HStack {
                            Label("Token push", systemImage: "number")
                            Spacer()
                            Text(String(token.prefix(12)) + "…")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if vm.notificationStatus == .notDetermined || vm.notificationStatus == .denied {
                        Button {
                            if vm.notificationStatus == .denied {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                Task { await vm.requestNotifications() }
                            }
                        } label: {
                            Label(
                                vm.notificationStatus == .denied ? "Ouvrir les Réglages" : "Activer les notifications",
                                systemImage: "bell.badge"
                            )
                            .foregroundStyle(blue)
                        }
                    }
                }

                // Photos soumises
                Section("Mes photos soumises") {
                    if vm.submissions.isEmpty {
                        Text("Aucune photo soumise pour le moment.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.submissions) { sub in
                            HStack(spacing: 12) {
                                // Miniature locale si disponible
                                if let img = UIImage(contentsOfFile: sub.localImagePath) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 48, height: 48)
                                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Boîte #\(sub.boxId)")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(sub.submittedAt, style: .relative)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                statusChip(sub.status)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Données
                Section("Données") {
                    Button(role: .destructive) {
                        vm.showCacheClearAlert = true
                    } label: {
                        HStack {
                            Label("Vider le cache", systemImage: "trash")
                            Spacer()
                            if vm.cacheClearDone {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                    .alert("Vider le cache ?", isPresented: $vm.showCacheClearAlert) {
                        Button("Vider", role: .destructive) { Task { await vm.clearCache() } }
                        Button("Annuler", role: .cancel) {}
                    } message: {
                        Text("Les boîtes seront rechargées depuis le serveur.")
                    }
                }

                // Crédits
                Section("À propos") {
                    Link(destination: URL(string: "https://www.boites-a-livres.fr")!) {
                        Label("boites-a-livres.fr", systemImage: "globe")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Données sous licence ODbL")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("© boites-a-livres.fr — Merci aux contributeurs")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.systemGray3))
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Réglages")
            .task { await vm.onAppear() }
        }
    }

    private var notifStatusLabel: String {
        switch vm.notificationStatus {
        case .authorized: return "Activées"
        case .denied: return "Refusées"
        case .provisional: return "Provisoires"
        case .notDetermined: return "Non configurées"
        default: return "Inconnu"
        }
    }

    private var notifStatusColor: Color {
        switch vm.notificationStatus {
        case .authorized: return .green
        case .denied: return .red
        default: return .secondary
        }
    }

    @ViewBuilder
    private func statusChip(_ status: PendingPhotoSubmission.SubmissionStatus) -> some View {
        let (label, color): (String, Color) = switch status {
        case .pending: ("En attente", .orange)
        case .approved: ("Acceptée", .green)
        case .rejected: ("Refusée", .red)
        }
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
