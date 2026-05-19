import SwiftUI
import UIKit
import UserNotifications
import StoreKit

// MARK: - Settings View

struct SettingsView: View {
    @State private var vm = SettingsViewModel()
    @AppStorage("colorSchemeIndex") private var colorSchemeIndex = 0
    @AppStorage("textSizeIndex") private var textSizeIndex = 0
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    @Environment(\.requestReview) private var requestReview

    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)
    private var shareText: String { NSLocalizedString("share_app_text", comment: "") }

    var body: some View {
        NavigationStack {
            List {
                unitsSection
                appearanceSection
                accessibilitySection
                shareSection
                notificationsSection
                submissionsSection
                deletionRequestsSection
                aboutSection
                cacheSection
                versionSection
            }
            .contentMargins(.bottom, 100, for: .scrollContent)
            .navigationTitle("Réglages")
            .task { await vm.onAppear() }
            .refreshable { await vm.onAppear() }
        }
    }

    // MARK: - Sections

    private var unitsSection: some View {
        Section {
            HStack {
                Label {
                    Text("Unités de distance")
                } icon: {
                    Image(systemName: "ruler")
                        .foregroundStyle(.purple)
                }
                Spacer()
                Picker("", selection: $useImperialUnits) {
                    Text("km").tag(false)
                    Text("miles").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
        } header: {
            Text("Unités")
        }
    }

    private var appearanceSection: some View {
        Section {
            HStack {
                Label {
                    Text("Affichage")
                } icon: {
                    Image(systemName: colorSchemeIndex == 2 ? "moon.fill" : "sun.max.fill")
                        .foregroundStyle(colorSchemeIndex == 2 ? .indigo : .orange)
                }
                Spacer()
                Picker("", selection: $colorSchemeIndex) {
                    Text("Auto").tag(0)
                    Text("Clair").tag(1)
                    Text("Sombre").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 165)
            }
        } header: {
            Text("Apparence")
        }
    }

    private var accessibilitySection: some View {
        Section {
            HStack(spacing: 14) {
                Label {
                    Text("Taille du texte")
                } icon: {
                    Image(systemName: "textformat.size")
                        .foregroundStyle(.blue)
                }
                Spacer()
                sizeButton(label: "A", size: 13, tag: 0)
                sizeButton(label: "A", size: 17, tag: 1)
                sizeButton(label: "A", size: 22, tag: 2)
            }
        } header: {
            Text("Accessibilité")
        } footer: {
            Text("Augmentez la taille pour une meilleure lisibilité.")
        }
    }

    @ViewBuilder
    private func sizeButton(label: String, size: CGFloat, tag: Int) -> some View {
        let selected = textSizeIndex == tag
        Button { textSizeIndex = tag } label: {
            Text(label)
                .font(.system(size: size, weight: selected ? .bold : .regular))
                .frame(width: 38, height: 34)
                .background(selected ? green.opacity(0.15) : Color(.systemGray5))
                .foregroundStyle(selected ? green : Color(.secondaryLabel))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(selected ? green.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
                .animation(.spring(response: 0.2), value: selected)
        }
        .buttonStyle(.plain)
    }

    private var shareSection: some View {
        Section {
            ShareLink(item: shareText) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Partager l'application")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.label))
                        Text("WhatsApp, SMS, e-mail…")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(green)
                }
            }

            Button {
                requestReview()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Noter l'application")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.label))
                        Text("Laisser un avis sur l'App Store")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Partager")
        } footer: {
            Text("Faites découvrir Boîtes à Livres à vos proches !")
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            HStack {
                Label("Statut", systemImage: "bell.fill")
                Spacer()
                Text(notifStatusKey)
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
                    .foregroundStyle(green)
                }
            }
        }
    }

    private var submissionsSection: some View {
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
                                image.resizable()
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
                            Text(boxTitle(sub.box_id))
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
    }

    private var deletionRequestsSection: some View {
        Section("Mes demandes de suppression") {
            if vm.deletionRequests.isEmpty {
                Text("Aucune demande envoyée depuis cet appareil.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.deletionRequests) { req in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 48, height: 48)
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 18))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(boxTitle(req.box_id))
                                .font(.system(size: 14, weight: .semibold))
                            Text(req.reason)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text(relativeDate(from: req.created_at))
                                .font(.system(size: 11))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }

                        Spacer()
                        deletionStatusChip(req.status)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func deletionStatusChip(_ status: String) -> some View {
        let (label, color): (String, Color) = switch status {
            case "pending":  ("En attente", .orange)
            case "approved": ("Supprimée", .red)
            case "rejected": ("Refusée", .secondary)
            default:         (status, .secondary)
        }
        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var aboutSection: some View {
        Section("À propos") {
            Text("Bénévolement :")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.label))

            Link(destination: URL(string: "https://malikkaraoui.com")!) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Une application proposée par")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("Malik Karaoui")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(green)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }

            Link(destination: URL(string: "https://www.boites-a-livres.fr")!) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Données issues de")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("boites-a-livres.fr")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(green)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var cacheSection: some View {
        Section {
            Button(role: .destructive) {
                vm.showCacheClearAlert = true
            } label: {
                Label(
                    vm.cacheClearDone ? "Cache vidé" : "Vider le cache",
                    systemImage: vm.cacheClearDone ? "checkmark.circle.fill" : "trash.fill"
                )
            }
            .alert("Vider le cache ?", isPresented: $vm.showCacheClearAlert) {
                Button("Vider", role: .destructive) { Task { await vm.clearCache() } }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Les boîtes seront rechargées depuis le serveur.")
            }
        } footer: {
            Text("Supprime les données mises en cache localement.")
        }
    }

    private var versionSection: some View {
        Section {
            HStack(spacing: 14) {
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Boîtes à Livres")
                        .font(.system(size: 15, weight: .semibold))
                    Text(versionLabel)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        } header: {
            Text("Version")
        }
    }

    // MARK: - Helpers

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "v\(version)"
    }

    private var notifStatusKey: LocalizedStringKey {
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
        let (label, color): (LocalizedStringKey, Color) = switch status {
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
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .short
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return iso8601String
    }

    private func boxTitle(_ id: Int) -> String {
        String(format: NSLocalizedString("Boîte #%lld", comment: ""), id)
    }
}
