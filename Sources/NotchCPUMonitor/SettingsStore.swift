import Foundation

enum MetricType: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
    case gpu = "GPU"
}

final class SettingsStore: ObservableObject {
    @Published var refreshInterval: TimeInterval {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }

    @Published var startAtLogin: Bool {
        didSet { UserDefaults.standard.set(startAtLogin, forKey: "startAtLogin") }
    }

    @Published var selectedMetric: MetricType {
        didSet { UserDefaults.standard.set(selectedMetric.rawValue, forKey: "selectedMetric") }
    }

    init() {
        let stored = UserDefaults.standard.double(forKey: "refreshInterval")
        self.refreshInterval = stored > 0 ? stored : 2.0
        self.startAtLogin = UserDefaults.standard.bool(forKey: "startAtLogin")

        let metricRaw = UserDefaults.standard.string(forKey: "selectedMetric") ?? "CPU"
        self.selectedMetric = MetricType(rawValue: metricRaw) ?? .cpu
    }
}
