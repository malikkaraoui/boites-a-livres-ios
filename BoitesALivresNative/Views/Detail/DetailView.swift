import SwiftUI
import UIKit
import MapKit

struct DetailView: View {
    let boxId: Int
    @State private var vm = DetailViewModel()
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showDMS = false
    @State private var photoViewerIndex: Int? = nil
    @State private var coordCopied = false
    @State private var coordRotating = false

    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)

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

                        // Localisation — coordonnées GPS + bouton Maps
                        sectionCard {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionTitle("Localisation")
                                coordToggleRow(box: box)
                                mapsButton(box: box)
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

                        // Ajout photo
                        sectionCard {
                            VStack(spacing: 8) {
                                photoAddButton(box: box)
                                Text("Les nouvelles photos sont publiées après validation manuelle.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
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
                                                        .foregroundStyle(green)
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
                }
                .refreshable { await vm.refresh(boxId: boxId) }
                .navigationTitle("#\(box.id) — \(box.city ?? "Détail")")
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 90)
                }
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
        .sheet(isPresented: $vm.photoSubmitted) {
            PhotoSubmittedView()
        }
        .sheet(isPresented: $vm.showPhotoModal) {
            photoPickerSheet
        }
        .fullScreenCover(isPresented: Binding(
            get: { photoViewerIndex != nil },
            set: { if !$0 { photoViewerIndex = nil } }
        )) {
            FullScreenPhotoViewer(photos: vm.photos, startIndex: photoViewerIndex ?? 0)
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

    @ViewBuilder
    private func photoSection(box: BookBox) -> some View {
        ZStack(alignment: .topTrailing) {
            PhotoCarousel(
                photos: vm.photos,
                localImage: vm.localPhotoImage,
                uploading: vm.uploading,
                onTap: { index in photoViewerIndex = index }
            )
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

    // Ligne GPS avec format Décimal/DMS basculable au tap
    @ViewBuilder
    private func coordToggleRow(box: BookBox) -> some View {
        let coordValue = showDMS
            ? "\(dms(box.lat, isLat: true)) \(dms(box.lng, isLat: false))"
            : String(format: "%.6f, %.6f", box.lat, box.lng)

        HStack(alignment: .center, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showDMS.toggle()
                    coordRotating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    coordRotating = false
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(showDMS ? LocalizedStringKey("DMS") : "Décimal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(coordValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(.label))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13))
                        .foregroundStyle(green.opacity(0.8))
                        .rotationEffect(.degrees(coordRotating ? 180 : 0))
                        .animation(.easeInOut(duration: 0.35), value: coordRotating)
                }
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 28)
                .padding(.horizontal, 12)

            Button {
                UIPasteboard.general.string = coordValue
                withAnimation(.spring(duration: 0.2)) { coordCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) { coordCopied = false }
                }
            } label: {
                Image(systemName: coordCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(coordCopied ? .green : green)
                    .frame(width: 40, height: 40)
                    .background(coordCopied ? Color.green.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.spring(duration: 0.2), value: coordCopied)
            }
        }
    }

    // Bouton Maps avec icône et fond vert
    private func mapsButton(box: BookBox) -> some View {
        Button { openMaps(box: box) } label: {
            Label("Ouvrir dans Plans", systemImage: "map.fill")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: green.opacity(0.35), radius: 8, y: 4)
        }
    }

    @ViewBuilder
    private func photoAddButton(box: BookBox) -> some View {
        let canAdd = vm.photos.count < Constants.maxPhotosPerBox
        Button {
            if canAdd { vm.showPhotoModal = true }
        } label: {
            HStack(spacing: 8) {
                if vm.uploading {
                    ProgressView().tint(green)
                } else {
                    Image(systemName: "camera.fill").foregroundStyle(green)
                    Group {
                        if canAdd {
                            Text("Ajouter une photo (\(vm.photos.count)/\(Constants.maxPhotosPerBox) publiées)")
                        } else {
                            Text("Maximum \(Constants.maxPhotosPerBox) photos atteint")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canAdd ? green : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(canAdd ? green.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(canAdd ? 1 : 0.6)
        }
        .disabled(vm.uploading || !canAdd)
    }

    private var photoPickerSheet: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Ajouter une photo")
                    .font(.system(size: 17, weight: .bold))
                Text("Boîte #\(boxId)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            VStack(spacing: 12) {
                Button {
                    vm.showPhotoModal = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCamera = true }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Prendre une photo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(.label))
                            Text("Recommandé — inclut ta position GPS")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(green.opacity(0.35), lineWidth: 1))
                }

                Button {
                    vm.showPhotoModal = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showLibrary = true }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(green)
                            .frame(width: 44, height: 44)
                            .background(green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Choisir depuis la bibliothèque")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(.label))
                            Text("Sans données de localisation")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2), lineWidth: 1))
                }

                Button("Annuler") { vm.showPhotoModal = false }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(28)
    }

    // MARK: - UI Helpers

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
            .padding(.horizontal, 16)
            .padding(.top, 12)
    }

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 148/255, green: 163/255, blue: 184/255))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.bottom, 4)
    }

    // MARK: - Logic

    private func openMaps(box: BookBox) {
        let url = URL(string: "maps://?ll=\(box.lat),\(box.lng)&q=Boîte+à+livres")
            ?? URL(string: "http://maps.apple.com/?ll=\(box.lat),\(box.lng)")!
        UIApplication.shared.open(url)
    }

    private func dms(_ deg: Double, isLat: Bool) -> String {
        let abs = Swift.abs(deg)
        let d = Int(abs)
        let m = Int((abs - Double(d)) * 60)
        let s = Int(((abs - Double(d)) * 60 - Double(m)) * 60)
        let dir = isLat ? (deg >= 0 ? "N" : "S") : (deg >= 0 ? "E" : "O")
        return "\(d)°\(m)'\(s)\"\(dir)"
    }

    private func formatDist(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
    }
}
