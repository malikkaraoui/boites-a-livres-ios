import MapKit
import SwiftUI

// MARK: - Add Box View (two-step: map → form)

struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = AddBoxViewModel()
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @FocusState private var isNotesFocused: Bool

    private let green = Color(red: 0.102, green: 0.718, blue: 0.608)
    private let notesLimit = 100

    var body: some View {
        NavigationStack {
            Group {
                switch vm.step {
                case .map:  mapStep
                case .form: formStep
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                showCamera = false
                if let image { vm.selectedImage = image }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            LibraryPickerView { image in
                showLibrary = false
                if let image { vm.selectedImage = image }
            }
        }
    }

    // MARK: Step 1 — Map

    private var mapStep: some View {
        ZStack {
            Map(position: $vm.cameraPosition)
                .onMapCameraChange(frequency: .continuous) { ctx in
                    vm.pinCoordinate = ctx.region.center
                }
                .ignoresSafeArea()

            // Fixed center pin
            VStack(spacing: 0) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(green)
                    .shadow(color: green.opacity(0.4), radius: 8)
                Rectangle()
                    .fill(green)
                    .frame(width: 2, height: 10)
                Ellipse()
                    .fill(green.opacity(0.25))
                    .frame(width: 10, height: 4)
            }

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text("Déplacer la carte pour placer la boîte")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Button {
                        Task { await vm.confirmPosition() }
                    } label: {
                        HStack {
                            if vm.isGeocoding { ProgressView().tint(.white) }
                            Text(vm.isGeocoding ? "Localisation…" : "Confirmer la position →")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(vm.isGeocoding)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Étape 1 / 2 — Position")
    }

    // MARK: Step 2 — Form

    private var formStep: some View {
        Group {
            if vm.submitted { successView } else { formContent }
        }
    }

    private var formContent: some View {
        ScrollView {
            // Tap anywhere outside a field → clavier rétracté
            Color.clear
                .frame(height: 0)
                .contentShape(Rectangle())

            VStack(spacing: 16) {

                // Address fields
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Adresse")
                    TextField("Adresse", text: $vm.address)
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            fieldLabel("Ville")
                            TextField("Ville", text: $vm.city)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            fieldLabel("Code postal")
                            TextField("Code postal", text: $vm.postalCode)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        .frame(width: 110)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Photo section
                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Photo (optionnel)")

                    if let image = vm.selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Button {
                                vm.selectedImage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 3)
                            }
                            .padding(8)
                        }
                        Button {
                            showPhotoOptions = true
                        } label: {
                            Label("Changer la photo", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(green)
                        }
                    } else {
                        Button {
                            showPhotoOptions = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ajouter une photo")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color(.label))
                                    Text("Aide à identifier la boîte sur la carte")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(14)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(.separator), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Notes — limited to 100 chars
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Note (optionnel)")
                    TextField("Ex : devant la mairie, à côté de la fontaine…",
                              text: $vm.notes, axis: .vertical)
                        .lineLimit(3...5)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNotesFocused)
                        .onChange(of: vm.notes) { _, new in
                            if new.count > notesLimit {
                                vm.notes = String(new.prefix(notesLimit))
                            }
                        }
                    HStack {
                        Spacer()
                        Text("\(vm.notes.count)/\(notesLimit)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(vm.notes.count >= notesLimit ? .orange : Color(.tertiaryLabel))
                            .animation(.easeInOut(duration: 0.15), value: vm.notes.count)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Coords + relocate
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(green)
                        .font(.system(size: 13))
                    Text(String(format: "%.5f° N, %.5f° E",
                                vm.pinCoordinate.latitude,
                                vm.pinCoordinate.longitude))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Replacer") { vm.step = .map }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(green)
                }
                .padding(.horizontal, 16)

                if let err = vm.errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                }

                Button {
                    Task {
                        let token = NotificationService.shared.getPushToken()
                        await vm.submit(deviceToken: token)
                    }
                } label: {
                    HStack {
                        if vm.isSubmitting { ProgressView().tint(.white) }
                        Text(vm.isSubmitting ? "Envoi…" : "Soumettre la boîte")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(vm.isSubmitting)

                Text("Votre soumission sera examinée par l'équipe et vous recevrez une notification à la décision.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture { isNotesFocused = false }
        .navigationTitle("Étape 2 / 2 — Détails")
        .confirmationDialog("Ajouter une photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
            Button("Prendre une photo") { showCamera = true }
            Button("Choisir dans la bibliothèque") { showLibrary = true }
            Button("Annuler", role: .cancel) {}
        }
    }

    // MARK: Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(green)
            Text("Boîte soumise !")
                .font(.system(size: 24, weight: .bold))
            Text("Votre demande est en attente de validation.\nVous recevrez une notification à la décision.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Fermer") { dismiss() }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(green)
                .clipShape(Capsule())
            Spacer()
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
