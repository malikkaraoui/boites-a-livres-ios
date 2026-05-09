import SwiftUI
import UIKit
import MapKit

struct DetailView: View {
    let boxId: Int
    @State private var vm = DetailViewModel()
    @State private var showCamera = false
    @State private var showLibrary = false

    private let blue = Color(red: 37/255, green: 99/255, blue: 235/255)

    var body: some View {
        Group {
            if vm.loading && vm.box == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let box = vm.box {
                ScrollView {
                    VStack(spacing: 0) {
                        // Photo carousel
                        if !vm.photos.isEmpty || vm.localPhotoImage != nil || vm.uploading {
                            photoSection(box: box)
                        }

                        // Localisation
                        sectionCard {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("Localisation")
                                coordRow(label: "Décimal",
                                         value: String(format: "%.7f, %.7f", box.lat, box.lng))
                                coordRow(label: "DMS",
                                         value: "\(dms(box.lat, isLat: true)) \(dms(box.lng, isLat: false))")
                                actionBtn("Ouvrir dans Plans / Maps") { openMaps(box: box) }
                            }
                        }

                        // Adresse
                        sectionCard {
                            VStack(alignment: .leading, spacing: 6) {
                                sectionTitle("Adresse")
                                if let addr = box.address {
                                    Text(addr).font(.system(size: 15)).foregroundStyle(Color(.label))
                                }
                                if let cp = box.postal_code, let city = box.city {
                                    Text("\(cp) \(city)").font(.system(size: 15)).foregroundStyle(Color(.label))
                                }
                                if let dept = box.department {
                                    Text("Département \(dept)").font(.system(size: 13)).foregroundStyle(.secondary)
                                }
                            }
                        }

                        // Actions
                        sectionCard {
                            VStack(spacing: 8) {
                                photoAddButton(box: box)
                                Text("Les nouvelles photos sont publiées après validation manuelle.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                actionBtn("Voir sur boites-a-livres.fr") {
                                    if let url = box.detailURL {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }

                        // Nearby boxes
                        if !vm.nearbyBoxes.isEmpty {
                            sectionCard {
                                VStack(alignment: .leading, spacing: 0) {
                                    sectionTitle("À proximité (\(vm.nearbyBoxes.count))")
                                    ForEach(vm.nearbyBoxes) { nearby in
                                        NavigationLink(value: nearby.id) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("#\(nearby.id) — \(nearby.city ?? "—")")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(Color(.label))
                                                }
                                                Spacer()
                                                if let dist = nearby.distance_m {
                                                    Text(formatDist(dist))
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundStyle(blue)
                                                }
                                            }
                                            .padding(.vertical, 10)
                                        }
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .refreshable { await vm.refresh(boxId: boxId) }
                .navigationTitle("#\(box.id) — \(box.city ?? "Détail")")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Boîte introuvable")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await vm.load(boxId: boxId) }
        .alert(vm.alertTitle, isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
        .sheet(isPresented: $vm.showPhotoModal) {
            photoPickerSheet
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                showCamera = false
                if let img = image { Task { await vm.submitPhoto(img, boxId: boxId) } }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            LibraryPickerView { image in
                showLibrary = false
                if let img = image { Task { await vm.submitPhoto(img, boxId: boxId) } }
            }
        }
    }

    // MARK: - Views

    // Display photo carousel with upload progress indicator overlay
    @ViewBuilder
    private func photoSection(box: BookBox) -> some View {
        ZStack(alignment: .topTrailing) {
            PhotoCarousel(photos: vm.photos, localImage: vm.localPhotoImage, uploading: vm.uploading)
            if vm.uploading && (!vm.photos.isEmpty || vm.localPhotoImage != nil) {
                HStack(spacing: 6) {
                    ProgressView().tint(.white).scaleEffect(0.8)
                    Text("Envoi en cours…").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.black.opacity(0.65))
                .clipShape(Capsule())
                .padding(12)
            }
        }
    }

    // Button to add photo; disabled if photo limit reached or upload in progress
    @ViewBuilder
    private func photoAddButton(box: BookBox) -> some View {
        let canAdd = vm.photos.count < Constants.maxPhotosPerBox
        Button {
            if canAdd { vm.showPhotoModal = true }
        } label: {
            HStack(spacing: 8) {
                if vm.uploading {
                    ProgressView().tint(blue)
                } else {
                    Image(systemName: "camera.fill").foregroundStyle(blue)
                    Text(canAdd
                         ? "Ajouter une photo (\(vm.photos.count)/\(Constants.maxPhotosPerBox) publiées)"
                         : "Maximum \(Constants.maxPhotosPerBox) photos atteint")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canAdd ? blue : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(canAdd ? Color(red: 239/255, green: 246/255, blue: 255/255) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(canAdd ? 1 : 0.6)
        }
        .disabled(vm.uploading || !canAdd)
    }

    // Bottom sheet for selecting camera or library photo source
    private var photoPickerSheet: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color(.systemGray4)).frame(width: 36, height: 5).padding(.top, 8)
            Text("Ajouter une photo").font(.system(size: 16, weight: .bold)).padding(.top, 16)

            VStack(spacing: 10) {
                Button {
                    vm.showPhotoModal = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCamera = true }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("📷 Prendre une photo").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(.label))
                        Text("Recommandé — inclut ta position GPS").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    vm.showPhotoModal = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showLibrary = true }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🖼 Choisir depuis la bibliothèque").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color(.label))
                        Text("Sans données de localisation automatiques").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Annuler") { vm.showPhotoModal = false }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - UI Helpers

    // Reusable card container with shadow and rounded corners
    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
            .padding(.horizontal, 16)
            .padding(.top, 12)
    }

    // Uppercase section header with slate color
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.bottom, 4)
    }

    // Coordinate row with copy-to-clipboard button
    @ViewBuilder
    private func coordRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(.secondary)
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Text("\(value) 📋")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(blue)
            }
        }
    }

    // Reusable action button with blue text and gray background
    private func actionBtn(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Logic

    // Open Apple Maps or Google Maps with box location
    private func openMaps(box: BookBox) {
        let url = URL(string: "maps://?ll=\(box.lat),\(box.lng)&q=Boîte+à+livres")
            ?? URL(string: "http://maps.apple.com/?ll=\(box.lat),\(box.lng)")!
        UIApplication.shared.open(url)
    }

    // Convert decimal degrees to DMS (degrees, minutes, seconds) with N/S/E/O cardinal direction
    private func dms(_ deg: Double, isLat: Bool) -> String {
        let abs = Swift.abs(deg)
        let d = Int(abs)
        let m = Int((abs - Double(d)) * 60)
        let s = Int(((abs - Double(d)) * 60 - Double(m)) * 60)
        let dir = isLat ? (deg >= 0 ? "N" : "S") : (deg >= 0 ? "E" : "O")
        return "\(d)°\(m)'\(s)\"\(dir)"
    }

    // Format distance in meters as meters or kilometers with appropriate precision
    private func formatDist(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
    }
}
