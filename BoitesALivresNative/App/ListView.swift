import SwiftUI

struct ListView: View {
    @Binding var path: NavigationPath
    @State private var vm = ListViewModel()
    @ObservedObject private var locationService = LocationService.shared
    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Filter bar
                filterBar

                if vm.loading && vm.boxes.isEmpty {
                    Spacer()
                    ProgressView().scaleEffect(1.3)
                    Spacer()
                } else if let err = vm.errorMessage, vm.boxes.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text(err).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Réessayer") { Task { await vm.initialLoad() } }
                            .buttonStyle(.borderedProminent).tint(blue)
                    }
                    .padding(32)
                    Spacer()
                } else {
                    List {
                        ForEach(vm.boxes) { box in
                            NavigationLink(value: box.id) {
                                BookBoxRow(box: box)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparatorTint(Color(.systemGray5))
                        }

                        if vm.hasMore || vm.loadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .task { await vm.loadMore() }
                        } else if !vm.boxes.isEmpty {
                            Text("\(vm.boxes.count) boîtes chargées")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Boîtes à livres")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Int.self) { id in
                DetailView(boxId: id)
            }
            .task {
                if vm.boxes.isEmpty { await vm.initialLoad() }
            }
            .refreshable { await vm.initialLoad() }
            .onReceive(locationService.$currentLocation.compactMap { $0 }) { newLoc in
                Task { await vm.reloadIfMovedFar(newLocation: newLoc) }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            // Radius chips
            ForEach(Constants.radiusOptionsKm, id: \.self) { km in
                filterChip(
                    label: "\(Int(km)) km",
                    isSelected: vm.radiusKm == km
                ) {
                    if vm.radiusKm != km {
                        vm.radiusKm = km
                        Task { await vm.applyFilters() }
                    }
                }
            }

            // Photo toggle : actif (bleu) = avec photo only / inactif = toutes
            Button {
                vm.photoFilter = (vm.photoFilter == .withPhoto) ? .all : .withPhoto
                Task { await vm.applyFilters() }
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(vm.photoFilter == .withPhoto ? .white : Color(.label))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(vm.photoFilter == .withPhoto ? blue : Color(.systemGray6))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color(.label))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? blue : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}

struct BookBoxRow: View {
    let box: BookBox
    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)

    var body: some View {
        HStack(spacing: 12) {
            // Icône
            ZStack {
                Circle()
                    .fill(box.has_photo ? Color(red: 239/255, green: 246/255, blue: 255/255) : Color(.systemGray6))
                    .frame(width: 44, height: 44)
                Image(systemName: box.has_photo ? "book.fill" : "book")
                    .foregroundStyle(box.has_photo ? blue : Color(.systemGray2))
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Boîte #\(box.id)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                if let city = box.city {
                    Text(city)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                if let addr = box.address {
                    Text(addr)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.systemGray2))
                        .lineLimit(1)
                }
            }

            Spacer()

            if let dist = box.distance_m {
                Text(formatDist(dist))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(blue)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDist(_ m: Double) -> String {
        m < 1000 ? "\(Int(m)) m" : String(format: "%.1f km", m / 1000)
    }
}
