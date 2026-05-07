import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapScreen()
                .tabItem {
                    Label("Carte", systemImage: "map.fill")
                }
            ListView()
                .tabItem {
                    Label("Liste", systemImage: "list.bullet")
                }
            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gear")
                }
        }
        .tint(Color(red: 37/255, green: 99/255, blue: 235/255))
    }
}
