import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: NotchOverlayWindow!
    private let cpuProvider = CPUStatsProvider()
    private let memoryProvider = MemoryStatsProvider()
    private let gpuProvider = GPUStatsProvider()
    private let settings = SettingsStore()
    private let loginItemManager = LoginItemManager()

    private var notchWidth: CGFloat = 200
    private var notchHeight: CGFloat = 32

    func applicationDidFinishLaunching(_ notification: Notification) {
        detectNotchDimensions()
        setupOverlayWindow()
        cpuProvider.start(interval: settings.refreshInterval)
        memoryProvider.update()
        gpuProvider.update()

        // Update memory and GPU stats on the same timer as CPU
        Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            self?.memoryProvider.update()
            self?.gpuProvider.update()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func detectNotchDimensions() {
        guard let screen = NSScreen.main else { return }
        let safeAreaTop = screen.safeAreaInsets.top

        if safeAreaTop > 0 {
            notchHeight = safeAreaTop

            if let leftArea = screen.auxiliaryTopLeftArea,
               let rightArea = screen.auxiliaryTopRightArea {
                notchWidth = rightArea.minX - leftArea.maxX
            } else {
                notchWidth = 200
            }
        } else {
            notchHeight = 32
            notchWidth = 0
        }
    }

    private func setupOverlayWindow() {
        overlayWindow = NotchOverlayWindow()

        // Window starts at midX - 20, notch right edge is at midX + notchWidth/2
        // So text must start at notchWidth/2 + 20 from window left edge
        let leftInset = notchWidth / 2 + 20 + 4

        let overlayView = NotchOverlayView(
            cpuProvider: cpuProvider,
            memoryProvider: memoryProvider,
            gpuProvider: gpuProvider,
            settings: settings,
            loginItemManager: loginItemManager,
            notchHeight: notchHeight,
            leftInset: leftInset,
            onRefreshRateChange: { [weak self] interval in
                self?.cpuProvider.updateInterval(interval)
            }
        )

        let hostingView = NSHostingView(rootView: overlayView)

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: notchHeight))
        hostingView.frame = containerView.bounds
        hostingView.autoresizingMask = [.width, .height]
        containerView.addSubview(hostingView)

        overlayWindow.contentView = containerView

        positionWindow()
        overlayWindow.orderFrontRegardless()
    }

    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame

        // Position window so left edge overlaps with notch right edge
        let wingWidth: CGFloat = 240
        let totalHeight = notchHeight + 400
        // Well inside the notch — black on black, invisible
        let x = screenFrame.midX - 20
        let y = screenFrame.maxY - totalHeight

        overlayWindow.setFrame(
            NSRect(x: x, y: y, width: wingWidth, height: totalHeight),
            display: true
        )
    }

    @objc private func screenParametersChanged() {
        detectNotchDimensions()
        positionWindow()
    }
}
