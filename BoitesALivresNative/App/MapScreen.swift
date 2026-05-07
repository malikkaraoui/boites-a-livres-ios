import SwiftUI
import MapKit

struct MapScreen: View {
    @State private var vm = MapViewModel()
    @State private var path = NavigationPath()

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)
    private let gray = Color(red: 100/255, green: 116/255, blue: 139/255)

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
                                .onTapGesture { vm.selectedBox = box }
                        }
                    }
                    UserAnnotation()
                }
                .mapControls { MapCompass() }
                .ignoresSafeArea()

                // Header overlay
                VStack(spacing: 8) {
                    HStack {
                        // Radius picker
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

                        Spacer()

                        Button { vm.centerOnUser() } label: {
                            Text("📍")
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        }
                    }

                    HStack {
                        Text("\(vm.boxes.count) boîtes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

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
            .sheet(item: $vm.selectedBox) { box in
                BookBoxSheet(box: box) {
                    vm.selectedBox = nil
                    path.append(box.id)
                }
                .presentationDetents([.height(box.has_photo ? 320 : 200)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(200)))
            }
            .navigationDestination(for: Int.self) { id in
                DetailView(boxId: id)
            }
            .task { await vm.onAppear() }
        }
    }
}
