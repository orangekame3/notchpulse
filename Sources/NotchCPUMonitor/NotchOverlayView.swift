import AppKit
import SwiftUI

enum LoadLevel {
    case normal, warning, high

    init(usage: Double) {
        switch usage {
        case ..<60: self = .normal
        case ..<85: self = .warning
        default:    self = .high
        }
    }

    var textColor: Color {
        switch self {
        case .normal:  return .white
        case .warning: return .orange
        case .high:    return .red
        }
    }
}

/// Shape: flat top + flat left, only bottom-right corner is rounded
struct WingShape: Shape {
    var radius: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct NotchOverlayView: View {
    @ObservedObject var cpuProvider: CPUStatsProvider
    @ObservedObject var memoryProvider: MemoryStatsProvider
    @ObservedObject var gpuProvider: GPUStatsProvider
    @ObservedObject var settings: SettingsStore
    let loginItemManager: LoginItemManager
    let notchHeight: CGFloat
    let leftInset: CGFloat
    let onRefreshRateChange: (TimeInterval) -> Void
    var onPanelToggle: ((Bool) -> Void)?

    @State private var isHovering = false
    @State private var isPanelOpen = false

    private var currentLoadLevel: LoadLevel {
        switch settings.selectedMetric {
        case .cpu:    return LoadLevel(usage: cpuProvider.totalUsage)
        case .memory: return LoadLevel(usage: memoryProvider.usagePercent)
        case .gpu:    return LoadLevel(usage: gpuProvider.utilization)
        }
    }

    private var metricLabel: String {
        switch settings.selectedMetric {
        case .cpu:    return "C"
        case .memory: return "M"
        case .gpu:    return "G"
        }
    }

    private var metricValue: Int {
        switch settings.selectedMetric {
        case .cpu:    return Int(cpuProvider.totalUsage)
        case .memory: return Int(memoryProvider.usagePercent)
        case .gpu:    return Int(gpuProvider.utilization)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Wing: black bar flush with notch
            HStack(spacing: 4) {
                // Fixed-width spacer: pushes text past the notch right edge
                Color.clear.frame(width: leftInset)

                Text(metricLabel)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                Text("\(metricValue)%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(currentLoadLevel.textColor)

                if isHovering || isPanelOpen {
                    detail
                        .transition(.opacity)
                }

                Spacer(minLength: 10)
            }
            .frame(height: notchHeight)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                WingShape(radius: isPanelOpen ? 0 : 14)
                    .fill(.black)
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.25)) {
                    isPanelOpen.toggle()
                }
                onPanelToggle?(isPanelOpen)
            }

            if isPanelOpen {
                DropdownPanelView(
                    settings: settings,
                    loginItemManager: loginItemManager,
                    onRefreshRateChange: onRefreshRateChange,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPanelOpen = false
                        }
                        onPanelToggle?(false)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var detail: some View {
        switch settings.selectedMetric {
        case .cpu:
            HStack(spacing: 4) {
                Text("U:\(Int(cpuProvider.userUsage))")
                Text("S:\(Int(cpuProvider.systemUsage))")
            }
            .font(.system(size: 9, weight: .regular, design: .monospaced))
            .foregroundColor(.white.opacity(0.45))
        case .memory:
            Text(String(format: "%.1f/%.0fG", memoryProvider.usedGB, memoryProvider.totalGB))
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
        case .gpu:
            Text("GPU")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
        }
    }
}
