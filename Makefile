APP_NAME := NotchPulse
BUNDLE_ID := com.orangekame3.NotchCPUMonitor
VERSION := 0.1.8
EXECUTABLE := NotchCPUMonitor

BUILD_DIR := .build
RELEASE_DIR := $(BUILD_DIR)/release
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
ARCHIVE_NAME := $(APP_NAME)-$(VERSION)-arm64.tar.gz

.PHONY: build release app clean install uninstall archive

# Debug build
build:
	swift build

# Release build (optimized)
release:
	swift build -c release --arch arm64

# Create .app bundle from release build
app: release
	@echo "Creating $(APP_NAME).app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(RELEASE_DIR)/$(EXECUTABLE)" "$(APP_BUNDLE)/Contents/MacOS/$(EXECUTABLE)"
	@cp "Sources/$(EXECUTABLE)/Info.plist" "$(APP_BUNDLE)/Contents/Info.plist"
	@cp "Sources/$(EXECUTABLE)/NotchPulse.icns" "$(APP_BUNDLE)/Contents/Resources/NotchPulse.icns"
	@codesign --force --sign - "$(APP_BUNDLE)"
	@echo "Built: $(APP_BUNDLE)"

# Create distributable archive
archive: app
	@echo "Creating archive..."
	@cd "$(BUILD_DIR)" && tar -czf "$(ARCHIVE_NAME)" "$(APP_NAME).app"
	@echo "Archive: $(BUILD_DIR)/$(ARCHIVE_NAME)"

# Install to /Applications
install: app
	@echo "Installing $(APP_NAME).app to /Applications..."
	@cp -r "$(APP_BUNDLE)" "/Applications/$(APP_NAME).app"
	@xattr -cr "/Applications/$(APP_NAME).app"
	@echo "Installed. Launch from /Applications or Spotlight."

# Uninstall
uninstall:
	@echo "Removing $(APP_NAME).app..."
	@rm -rf "/Applications/$(APP_NAME).app"
	@echo "Uninstalled."

# Clean build artifacts
clean:
	swift package clean
	@rm -rf "$(APP_BUNDLE)"
	@rm -f "$(BUILD_DIR)/$(ARCHIVE_NAME)"

# Run debug build
run: build
	@swift run
