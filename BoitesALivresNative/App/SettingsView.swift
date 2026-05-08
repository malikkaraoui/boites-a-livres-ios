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
                                CachedAsyncImage(url: URL(string: sub.url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 48, height: 48)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    case .empty:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 48, height: 48)
                                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                    case .failure:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 48, height: 48)
                                            .overlay(Image(systemName: "exclamationmark.circle").foregroundStyle(.secondary))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Boîte #\(sub.box_id)")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(relativeDate(from: sub.submitted_at))
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

                // Crédits
                Section("À propos") {
                    Text("Bénévolement :")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(.label))

                    Link(destination: URL(string: "https://malikkaraoui.com")!) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Une application proposée par")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("Malik Karaoui")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(blue)
                        }
                    }

                    Link(destination: URL(string: "https://www.geobib.fr")!) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("En se basant sur le travail de")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("Sylvain Machefert")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(blue)
                        }
                    }

                    Text("Merci aux contributeurs de boites-a-livres.fr")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.systemGray2))
                }

                // Vider le cache — collé sous "À propos"
                Section {
                    Button {
                        vm.showCacheClearAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text(vm.cacheClearDone ? "Cache vidé" : "Vider le cache")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.systemGray2))
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .alert("Vider le cache ?", isPresented: $vm.showCacheClearAlert) {
                        Button("Vider", role: .destructive) { Task { await vm.clearCache() } }
                        Button("Annuler", role: .cancel) {}
                    } message: {
                        Text("Les boîtes seront rechargées depuis le serveur.")
                    }
                }

                // Suivi de version — isolé tout en bas
                Section {
                    HStack {
                        Spacer()
                        Text(versionLabel)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(.systemGray3))
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Réglages")
            .task { await vm.onAppear() }
            .refreshable { await vm.onAppear() }
        }
    }

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        var dateStr = ""
        if let exePath = Bundle.main.executablePath,
           let attrs = try? FileManager.default.attributesOfItem(atPath: exePath),
           let date = attrs[.modificationDate] as? Date {
            let f = DateFormatter()
            f.dateFormat = "dd/MM HH:mm"
            f.locale = Locale(identifier: "fr_FR")
            dateStr = " · \(f.string(from: date))"
        }
        return "v\(version) (\(build))\(dateStr)"
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
    private func statusChip(_ status: String) -> some View {
        let (label, color): (String, Color) = switch status {
        case "pending": ("En attente", .orange)
        case "approved": ("Acceptée", .green)
        case "rejected": ("Refusée", .red)
        default: ("Inconnu", .gray)
        }
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func relativeDate(from iso8601String: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso8601String) {
            let components = Calendar.current.dateComponents([.second, .minute, .hour, .day], from: date, to: Date())
            if let day = components.day, day > 0 {
                return "\(day) jour\(day > 1 ? "s" : "") ago"
            } else if let hour = components.hour, hour > 0 {
                return "\(hour)h ago"
            } else if let minute = components.minute, minute > 0 {
                return "\(minute)m ago"
            } else {
                return "à l'instant"
            }
        }
        return iso8601String
    }
}
