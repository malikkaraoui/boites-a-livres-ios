import SwiftUI
import MapKit

// MARK: - Map View

struct MapScreen: View {
    @Binding var path: NavigationPath
    @State private var vm = MapViewModel()
    @State private var router = DeepLinkRouter.shared
    @State private var sheetDetent: PresentationDetent = .height(320)
    @State private var showAddBox = false
    @State private var isHandlingAnnotationTap = false
    @AppStorage("useImperialUnits") private var useImperialUnits = false
    @Namespace private var mapScope

    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)
    private let greenMuted = Color(red: 0.102, green: 0.718, blue: 0.608).opacity(0.45)

    private func radiusLabel(_ km: Double) -> String {
        useImperialUnits ? "\(Int((km / 1.60934).rounded())) mi" : "\(Int(km)) km"
    }

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
                Map(position: $vm.cameraPosition, scope: mapScope) {
                    ForEach(vm.boxes) { box in
                        Annotation("", coordinate: box.coordinate, anchor: .center) {
                            let isSelected = vm.selectedBox?.id == box.id
                            let pinColor = pinFillColor(for: box, isSelected: isSelected)
                            Circle()
                                .fill(pinColor)
                                .frame(width: isSelected ? 26 : 18, height: isSelected ? 26 : 18)
                                .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 3 : 2.5))
                                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                                .shadow(color: isSelected ? green.opacity(0.5) : .clear, radius: 6)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
                                .onTapGesture { selectBox(box) }
                        }
                    }
                    UserAnnotation()
                }
                .mapControls { }
                .mapStyle(currentMapStyle)
                .onMapCameraChange(frequency: .onEnd) { context in
                    vm.onCameraChange(camera: context.camera)
                }
                .simultaneousGesture(
                    TapGesture().onEnded {
                        guard !isHandlingAnnotationTap else {
                            isHandlingAnnotationTap = false
                            return
                        }
                        vm.selectedBox = nil
                    }
                )
                .ignoresSafeArea()

                // Header overlay — radius filter buttons and box count badge
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        ForEach(Constants.radiusOptionsKm, id: \.self) { km in
                            Button { lightHaptic(); vm.changeRadius(km) } label: {
                                Text(radiusLabel(km))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(vm.radiusKm == km ? .white : Color(.secondaryLabel))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(vm.radiusKm == km ? green : .clear)
                            }
                            .buttonStyle(ScaleButtonStyle())
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

                // Right-side control buttons — MapKit owns compass/location behavior, like Apple Plans.
                VStack(spacing: 8) {
                    MapCompass(scope: mapScope)
                        .frame(width: 44, height: 44)
                    Button { lightHaptic(); vm.cycleTracking() } label: {
                        Image(systemName: trackingIcon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(green)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Button { lightHaptic(); vm.cycleMapStyle() } label: {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(green)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Button { mediumHaptic(); showAddBox = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(green)
                            .clipShape(Circle())
                            .shadow(color: green.opacity(0.45), radius: 6, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
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
            .fullScreenCover(isPresented: $showAddBox) {
                AddBoxView()
            }
            .sheet(item: $vm.selectedBox) { box in
                let small: PresentationDetent = .height(box.photo_url != nil ? 320 : 200)
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
        .mapScope(mapScope)
    }

    // Couleur du pin : sélectionné = blanc ; sinon condition du dernier avis approuvé
    // si présent, fallback sur la teinte verte (saturée si photo, atténuée sinon).
    private func pinFillColor(for box: BookBox, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if let condStr = box.last_review_condition,
           let cond = BoxReview.Condition(rawValue: condStr) {
            return ConditionStyle.color(for: cond)
        }
        return box.photo_url != nil ? green : greenMuted
    }

    private var trackingIcon: String {
        switch vm.trackingMode {
        case .none: return "location"
        case .centered: return "location.fill"
        case .followHeading: return "location.north.line.fill"
        }
    }

    // Handle annotation tap: close sheet for previous box before showing sheet for new box
    private func selectBox(_ box: BookBox) {
        isHandlingAnnotationTap = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isHandlingAnnotationTap = false
        }

        let initial: PresentationDetent = .height(box.photo_url != nil ? 320 : 200)
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

