SCHEME = BoitesALivresNative
SIM = iPhone 17 Pro
BUNDLE_ID = com.malikkaraoui.boitesalivresapp
BUILD_DIR = .build

.PHONY: build run test clean doctor archive help

help:
	@echo "Cibles disponibles:"
	@echo "  make build   - Compile pour le simulateur"
	@echo "  make run     - Compile, lance le simulateur et installe l'app"
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
