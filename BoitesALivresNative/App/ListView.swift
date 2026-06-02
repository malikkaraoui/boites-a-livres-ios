import SwiftUI

private struct IdentifiableInt: Identifiable { let value: Int; var id: Int { value } }

// MARK: - List View

struct ListView: View {
    @Binding var path: NavigationPath
    @State private var vm = ListViewModel()
    @State private var showAddBox = false
    @State private var deletionBoxId: Int? = nil
    @ObservedObject private var locationService = LocationService.shared
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Filter bar with radius and photo toggles
                filterBar

                if vm.loading && vm.boxes.isEmpty {
                    Spacer()
                    ProgressView().scaleEffect(1.3)
                    Spacer()
                } else if let err = vm.errorMessage, vm.boxes.isEmpty {
                    // Network error state with retry action
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text(err).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Réessayer") { Task { await vm.initialLoad(force: true) } }
                            .buttonStyle(.borderedProminent).tint(green)
                    }
                    .padding(32)
                    Spacer()
                } else {
                    // Scrollable list with pagination support
                    List {
                        ForEach(vm.boxes) { box in
                            NavigationLink(value: box.id) {
                                BookBoxRow(box: box)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparatorTint(Color(.systemGray5))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deletionBoxId = box.id
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }

                        // Pagination footer — load next page or show total count
                        if vm.hasMore || vm.loadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .task { await vm.loadMore() }
                        } else if !vm.boxes.isEmpty {
                            Text(loadedBoxesLabel(vm.boxes.count))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 84) }
                }
            }
            .navigationTitle("Boîtes à livres")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddBox = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(green)
                    }
                }
            }
            .fullScreenCover(isPresented: $showAddBox) {
                AddBoxView()
            }
            .navigationDestination(for: Int.self) { id in
                DetailView(boxId: id)
            }
            .task {
                if vm.boxes.isEmpty { await vm.initialLoad() }
            }
            .refreshable { await vm.initialLoad(force: true) }
            // Auto-reload when user moves far from last fetch location
            .onReceive(locationService.$currentLocation.compactMap { $0 }) { newLoc in
                Task { await vm.reloadIfMovedFar(newLocation: newLoc) }
            }
            .sheet(item: Binding(
                get: { deletionBoxId.map { IdentifiableInt(value: $0) } },
                set: { deletionBoxId = $0?.value }
            )) { item in
                DeletionRequestSheet(boxId: item.value)
            }
        }
    }

    // Filter controls: radius chips and photo availability toggle
    private var filterBar: some View {
        HStack(spacing: 8) {
            // Radius chip buttons
            ForEach(Constants.radiusOptionsKm, id: \.self) { km in
                filterChip(
                    label: radiusLabel(km),
                    isSelected: vm.radiusKm == km
                ) {
                    if vm.radiusKm != km {
                        vm.radiusKm = km
                        Task { await vm.applyFilters() }
                    }
                }
            }

            // Toggle: active (green) = photos only, inactive = all boxes
            Button {
                lightHaptic()
                vm.photoFilter = (vm.photoFilter == .withPhoto) ? .all : .withPhoto
                Task { await vm.applyFilters() }
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(vm.photoFilter == .withPhoto ? .white : Color(.label))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(vm.photoFilter == .withPhoto ? green : Color(.systemGray6))
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func radiusLabel(_ km: Double) -> String {
        useImperialUnits ? "\(Int(km / 1.60934)) mi" : "\(Int(km)) km"
    }

private func loadedBoxesLabel(_ count: Int) -> String {
        String(format: NSLocalizedString("%lld boîtes chargées", comment: "Loaded boxes count"), count)
    }

    // Reusable filter chip button: highlight selected state with green background
    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button { lightHaptic(); action() } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color(.label))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? green : Color(.systemGray6))
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - List Row Component

struct BookBoxRow: View {
    let box: BookBox
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

    var body: some View {
        HStack(spacing: 12) {
            // Icon: filled green circle if has photo, empty gray otherwise
            ZStack {
                Circle()
                    .fill(box.photo_url != nil ? green.opacity(0.12) : Color(.systemGray6))
                    .frame(width: 44, height: 44)
                Image(systemName: box.photo_url != nil ? "book.fill" : "book")
                    .foregroundStyle(box.photo_url != nil ? green : Color(.systemGray2))
                    .font(.system(size: 18))
            }

            // Box info: ID, city, and address
            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: NSLocalizedString("Boîte #%lld", comment: "Book box title"), box.id))
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

            // Distance from user location
            if let dist = box.distance_m {
                Text(formatDist(dist))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(green)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDist(_ m: Double) -> String {
        if useImperialUnits {
            let miles = m / 1609.344
            return miles < 0.1 ? "\(Int(m * 3.28084)) ft" : String(format: "%.1f mi", miles)
        }
        return m < 1000 ? "\(Int(m)) m" : String(format: "%.1f km", m / 1000)
    }
}
