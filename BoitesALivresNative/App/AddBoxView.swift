import MapKit
import SwiftUI

// MARK: - Add Box View (two-step: map → form)

struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = AddBoxViewModel()
    // Observé : le bouton Soumettre se met à jour avec le GPS (F01 M0023, revue R017)
    @ObservedObject private var locationService = LocationService.shared
    @State private var showCamera = false
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
        .onAppear {
            // Position précise pendant la saisie : contrôle de présence sur place (F01 M0023, #31)
            LocationService.shared.requestAuthorization()
            LocationService.shared.beginPrecisionUpdates()
        }
        .onDisappear { LocationService.shared.endPrecisionUpdates() }
        // Premier fix GPS : la carte se centre dessus si l'utilisateur ne l'a pas encore déplacée (F01 M0041)
        .onReceive(locationService.$currentLocation.compactMap { $0 }) { vm.applyFirstFix($0) }
    }

    // MARK: Step 1 — Map

    private var mapStep: some View {
        ZStack {
            // Épingle fixe au centre : on glisse la carte, le repère reste au centre (F01 M0041)
            Map(position: $vm.cameraPosition) {
                UserAnnotation()
            }
            .ignoresSafeArea()
            .simultaneousGesture(DragGesture(minimumDistance: 4).onChanged { _ in vm.markMovedByUser() })
            .onMapCameraChange(frequency: .onEnd) { context in
                vm.followCamera(center: context.camera.centerCoordinate)
            }
            .overlay {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(green)
                    .shadow(color: green.opacity(0.4), radius: 8)
                    .offset(y: -18)
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text("Déplace la carte pour placer la boîte")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Button {
                        mediumHaptic()
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
                    .buttonStyle(ScaleButtonStyle())
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
        ScrollViewReader { proxy in
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
                        fieldLabel("Photo (obligatoire, prise sur place)")

                        if let image = vm.selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Button {
                                    lightHaptic()
                                    vm.selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 3)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(8)
                            }
                            Button {
                                lightHaptic()
                                showCamera = true
                            } label: {
                                Label("Changer la photo", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(green)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        } else {
                            Button {
                                lightHaptic()
                                showCamera = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Ajouter une photo")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color(.label))
                                        Text("Prends-la sur place. Aucune personne sur la photo.")
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
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Notes — 100 caractères, un seul saut de ligne d'affilée, hauteur fixe (F01 M0038, #38)
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("Note (optionnel)")
                        TextField("Ex : devant la mairie, à côté de la fontaine…",
                                  text: $vm.notes, axis: .vertical)
                            .lineLimit(5, reservesSpace: true)
                            .textFieldStyle(.roundedBorder)
                            .focused($isNotesFocused)
                            .onChange(of: vm.notes) { _, new in
                                let clean = String(NoteText.limitLineBreaks(new).prefix(notesLimit))
                                if clean != new { vm.notes = clean }
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
                    .id("notes")

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
                        Button { lightHaptic(); vm.returnToMap() } label: {
                            Text("Replacer")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(green)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)

                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }

                    Button {
                        mediumHaptic()
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
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(vm.isSubmitting || !vm.canSubmit)
                    .opacity(vm.canSubmit ? 1 : 0.5)

                    if let hint = vm.submitHint {
                        Text(hint)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

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
            // Le champ note reste visible au-dessus du clavier : on fait défiler jusqu'à lui à l'ouverture
            .onChange(of: isNotesFocused) { _, focused in
                guard focused else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    withAnimation { proxy.scrollTo("notes", anchor: .bottom) }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { isNotesFocused = false }
                }
            }
        }
        .navigationTitle("Étape 2 / 2 — Détails")
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
            Button { lightHaptic(); dismiss() } label: {
                Text("Fermer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(green)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
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
