import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var loadedTabs: Set<Int> = [0]
    @State private var router = DeepLinkRouter.shared
    @State private var mapPath = NavigationPath()
    @State private var listPath = NavigationPath()

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map — full screen, no safe area insets imposed
            if loadedTabs.contains(0) {
                MapScreen(path: $mapPath)
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)
            }

            // List — reserves bottom space for the floating tab bar
            if loadedTabs.contains(1) {
                ListView(path: $listPath)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 84) }
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)
            }

            // Settings — same bottom inset
            if loadedTabs.contains(2) {
                SettingsView()
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 110) }
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)
            }

            floatingTabBar
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { _, newTab in
            loadedTabs.insert(newTab)
            if newTab != 0 { mapPath = NavigationPath() }
            if newTab != 1 { listPath = NavigationPath() }
        }
        .onChange(of: router.pendingBoxId) { _, newValue in
            if newValue != nil { selectedTab = 0 }
        }
    }

    // Floating tab bar with glassmorphism and spring animation on selection
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "map", iconFill: "map.fill", titleKey: "Carte", tag: 0)
            tabButton(icon: "list.bullet", iconFill: "list.bullet", titleKey: "Liste", tag: 1)
            tabButton(icon: "gear", iconFill: "gear", titleKey: "Réglages", tag: 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                )
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 6)
        .padding(.horizontal, 24)
    }

    // Tab button with double-tap-to-pop behavior for list tab
    @ViewBuilder
    private func tabButton(icon: String, iconFill: String, titleKey: LocalizedStringKey, tag: Int) -> some View {
        let isSelected = selectedTab == tag
        Button {
            if isSelected {
                if tag == 0 { mapPath = NavigationPath() }
                if tag == 1 { listPath = NavigationPath() }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tag
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? iconFill : icon)
                    .font(.system(size: 20))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                Text(titleKey)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
