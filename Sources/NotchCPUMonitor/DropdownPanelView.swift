import SwiftUI

struct DropdownPanelView: View {
    @ObservedObject var settings: SettingsStore
    let loginItemManager: LoginItemManager
    let onRefreshRateChange: (TimeInterval) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Display metric picker
            settingSection("Display") {
                HStack(spacing: 6) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        Button {
                            settings.selectedMetric = metric
                        } label: {
                            Text(metric.rawValue)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(settings.selectedMetric == metric
                                              ? Color.white.opacity(0.2)
                                              : Color.white.opacity(0.05))
                                )
                                .foregroundColor(settings.selectedMetric == metric
                                                 ? .white : .white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            divider

            // Refresh rate
            settingSection("Refresh") {
                HStack(spacing: 6) {
                    ForEach([1.0, 2.0, 5.0], id: \.self) { interval in
                        Button {
                            settings.refreshInterval = interval
                            onRefreshRateChange(interval)
                        } label: {
                            Text("\(Int(interval))s")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(settings.refreshInterval == interval
                                              ? Color.white.opacity(0.2)
                                              : Color.white.opacity(0.05))
                                )
                                .foregroundColor(settings.refreshInterval == interval
                                                 ? .white : .white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            divider

            // Login item toggle
            HStack {
                Text("Start at Login")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button {
                    loginItemManager.toggle()
                    settings.startAtLogin = loginItemManager.isEnabled
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(settings.startAtLogin ? Color.green.opacity(0.6) : Color.white.opacity(0.1))
                        .frame(width: 36, height: 20)
                        .overlay(
                            Circle()
                                .fill(.white)
                                .frame(width: 16, height: 16)
                                .offset(x: settings.startAtLogin ? 8 : -8),
                            alignment: .center
                        )
                        .animation(.easeInOut(duration: 0.15), value: settings.startAtLogin)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            divider

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("\u{2318}Q")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.95))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private func settingSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .textCase(.uppercase)
                .tracking(1)

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
