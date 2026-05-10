import SwiftUI
import MapKit

// MARK: - Map View

struct MapScreen: View {
    @Binding var path: NavigationPath
    @State private var vm = MapViewModel()
    @State private var router = DeepLinkRouter.shared
    @State private var sheetDetent: PresentationDetent = .height(320)

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)
    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)
    private let greenMuted = Color(red: 0.102, green: 0.718, blue: 0.608).opacity(0.45)

    // Map style binding: convert internal enum to MapKit style for display
    private var currentMapStyle: MapStyle {
        switch vm.mapStyleMode {
        case .standard: return .standard
        case .hybrid: return .hybrid
        case .imagery: return .imagery
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                // Interactive map with book box annotations
                Map(position: $vm.cameraPosition) {
                    ForEach(vm.boxes) { box in
                        Annotation("", coordinate: box.coordinate, anchor: .center) {
                            // Blue circles for boxes with photos, gray for those without
                            Circle()
                                .fill(box.has_photo ? green : greenMuted)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1.5))
                                .onTapGesture { selectBox(box) }
                        }
                    }
                    UserAnnotation()
                }
                .mapControls { MapCompass() }
                .mapStyle(currentMapStyle)
                .ignoresSafeArea()

                // Header overlay — radius filter buttons and box count badge
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        ForEach(Constants.radiusOptionsKm, id: \.self) { km in
                            Button("\(Int(km)) km") { vm.changeRadius(km) }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(vm.radiusKm == km ? .white : Color(.secondaryLabel))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(vm.radiusKm == km ? green : .clear)
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                    // Display total nearby boxes count
                    Text(String(format: NSLocalizedString("%lld boîtes", comment: ""), Int64(vm.boxes.count)))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 4)

                // Right-side control buttons — location center and map style toggle
                VStack(spacing: 8) {
                    Button { vm.centerOnUser() } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(green)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    Button { vm.cycleMapStyle() } label: {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(green)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 12)
                .padding(.top, 60)

                // Loading spinner overlay
                if vm.loading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .padding()
                            .background(Color(.systemBackground).opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 100)
                    }
                }

                // Error message overlay
                if let msg = vm.errorMessage {
                    VStack {
                        Spacer().frame(height: 80)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Chargement impossible")
                                .font(.system(size: 14, weight: .bold))
                            Text(msg)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(.systemBackground).opacity(0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 12)
                        Spacer()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $vm.selectedBox) { box in
                let small: PresentationDetent = .height(box.has_photo ? 320 : 200)
                let trigger: PresentationDetent = .fraction(0.75)
                BookBoxSheet(box: box) {
                    let id = box.id
                    vm.selectedBox = nil
                    path.append(id)
                }
                .presentationDetents([small, trigger], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(28)
                .presentationBackgroundInteraction(.enabled(upThrough: small))
                .onChange(of: sheetDetent) { _, new in
                    guard new == trigger else { return }
                    let id = box.id
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { vm.selectedBox = nil }
                    sheetDetent = small
                    path.append(id)
                }
            }
            .navigationDestination(for: Int.self) { id in
                DetailView(boxId: id)
            }
            .task { await vm.onAppear() }
            .onChange(of: router.pendingBoxId) { _, newValue in
                guard let boxId = newValue else { return }
                path.append(boxId)
                router.pendingBoxId = nil
            }
            .onAppear {
                if let boxId = router.pendingBoxId {
                    path.append(boxId)
                    router.pendingBoxId = nil
                }
            }
        }
    }

    // Handle annotation tap: close sheet for previous box before showing sheet for new box
    private func selectBox(_ box: BookBox) {
        let initial: PresentationDetent = .height(box.has_photo ? 320 : 200)
        if let current = vm.selectedBox, current.id != box.id {
            vm.selectedBox = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                sheetDetent = initial
                vm.selectedBox = box
            }
        } else {
            sheetDetent = initial
            vm.selectedBox = box
        }
    }
}
