SCHEME = BoitesALivresNative
SIM = iPhone 17 Pro
BUNDLE_ID = com.malikkaraoui.boitesalivresapp
BUILD_DIR = .build
DEVICE_UDID = 00008101-001278EA36E9001E
DEVICE_CORE_ID = C3CFC878-6C8D-5B87-8B35-1CB108A4922A

.PHONY: build run device test clean doctor archive help

help:
	@echo "Cibles disponibles:"
	@echo "  make build   - Compile pour le simulateur"
	@echo "  make run     - Compile, lance le simulateur et installe l'app"
	@echo "  make device  - Compile et installe sur iPhone de Malik (USB)"
	@echo "  make test    - Lance les tests"
	@echo "  make clean   - Supprime le dossier de build"
	@echo "  make doctor  - Diagnostic de l'environnement"
	@echo "  make archive - Archive pour l'App Store"

build:
	xcodebuild -scheme "$(SCHEME)" \
		-destination 'platform=iOS Simulator,name=$(SIM)' \
		-configuration Debug \
		-derivedDataPath "$(BUILD_DIR)" \
		ONLY_ACTIVE_ARCH=YES \
		build 2>&1 | xcpretty || \
	xcodebuild -scheme "$(SCHEME)" \
		-destination 'platform=iOS Simulator,name=$(SIM)' \
		-configuration Debug \
		-derivedDataPath "$(BUILD_DIR)" \
		ONLY_ACTIVE_ARCH=YES \
		build

device:
	@echo "=== Build pour iPhone de Malik ($(DEVICE_UDID)) ==="
	xcodebuild -scheme "$(SCHEME)" \
		-destination 'platform=iOS,id=$(DEVICE_UDID)' \
		-configuration Debug \
		-derivedDataPath "$(BUILD_DIR)" \
		ONLY_ACTIVE_ARCH=YES \
		CODE_SIGN_STYLE=Automatic \
		-allowProvisioningUpdates \
		build 2>&1 | xcpretty || \
	xcodebuild -scheme "$(SCHEME)" \
		-destination 'platform=iOS,id=$(DEVICE_UDID)' \
		-configuration Debug \
		-derivedDataPath "$(BUILD_DIR)" \
		ONLY_ACTIVE_ARCH=YES \
		CODE_SIGN_STYLE=Automatic \
		-allowProvisioningUpdates \
		build
	@echo "=== Installation sur l'appareil ==="
	xcrun devicectl device install app \
		--device $(DEVICE_CORE_ID) \
		"$(BUILD_DIR)/Build/Products/Debug-iphoneos/$(SCHEME).app"
	@echo "=== Lancement ==="
	xcrun devicectl device process launch \
		--device $(DEVICE_CORE_ID) \
		$(BUNDLE_ID)
	@echo "=== App lancée sur iPhone de Malik ==="

run: build
	@UDID=$$(xcrun simctl list devices available | grep "$(SIM)" | grep -v unavailable | head -1 | grep -oE '[A-F0-9-]{36}'); \
	echo "Simulateur: $$UDID"; \
	xcrun simctl boot "$$UDID" 2>/dev/null || true; \
	open -a Simulator; \
	sleep 2; \
	xcrun simctl install "$$UDID" "$(BUILD_DIR)/Build/Products/Debug-iphonesimulator/$(SCHEME).app"; \
	xcrun simctl launch "$$UDID" $(BUNDLE_ID)

test:
	xcodebuild -scheme "$(SCHEME)" \
		-destination 'platform=iOS Simulator,name=$(SIM)' \
		-configuration Debug \
		-derivedDataPath "$(BUILD_DIR)" \
		test 2>&1 | xcpretty

clean:
	rm -rf "$(BUILD_DIR)"
	xcrun simctl uninstall booted $(BUNDLE_ID) 2>/dev/null || true

doctor:
	@echo "=== Xcode ===" && xcodebuild -version
	@echo "=== xcodegen ===" && xcodegen --version 2>/dev/null || echo "xcodegen non trouvé"
	@echo "=== Swift ===" && swift --version
	@echo "=== Simulateurs iPhone disponibles ===" && xcrun simctl list devices available | grep "iPhone 1"

archive:
	xcodebuild -scheme "$(SCHEME)" \
		-configuration Release \
		-derivedDataPath "$(BUILD_DIR)" \
		archive \
		-archivePath "$(SCHEME).xcarchive"
