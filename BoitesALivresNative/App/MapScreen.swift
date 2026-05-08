import SwiftUI
import MapKit

struct MapScreen: View {
    @State private var vm = MapViewModel()
    @State private var path = NavigationPath()
    @State private var router = DeepLinkRouter.shared
    @State private var sheetDetent: PresentationDetent = .height(320)

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)
    private let gray = Color(red: 100/255, green: 116/255, blue: 139/255)

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
                Map(position: $vm.cameraPosition) {
                    ForEach(vm.boxes) { box in
                        Annotation("", coordinate: box.coordinate, anchor: .center) {
                            Circle()
                                .fill(box.has_photo ? blue : gray)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                                .onTapGesture { selectBox(box) }
                        }
                    }
                    UserAnnotation()
                }
                .mapControls { MapCompass() }
                .mapStyle(currentMapStyle)
                .ignoresSafeArea()

                // Header overlay — picker km + pastille à gauche, collés
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        ForEach(Constants.radiusOptionsKm, id: \.self) { km in
                            Button("\(Int(km)) km") { vm.changeRadius(km) }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(vm.radiusKm == km ? .white : Color(.systemGray))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(vm.radiusKm == km ? blue : .clear)
                        }
                    }
                    .background(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                    Text("\(vm.boxes.count) boîtes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 4)

                // Boutons à droite — overlay indépendant
                VStack(spacing: 8) {
                    Button { vm.centerOnUser() } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(blue)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    Button { vm.cycleMapStyle() } label: {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(blue)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 12)
                .padding(.top, 60)

                // Loading
                if vm.loading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .padding()
                            .background(.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 100)
                    }
                }

                // Error
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
                        .background(.white.opacity(0.96))
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

    /// Tap sur une annotation : si un sheet est déjà présenté pour une autre boîte,
    /// on ferme d'abord et on ré-ouvre après l'animation pour que le detent
    /// soit recalculé proprement (sinon le sheet reste sur l'ancien detent UIKit).
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
