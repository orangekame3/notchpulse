import Foundation
import Darwin

final class CPUStatsProvider: ObservableObject {
    @Published var totalUsage: Double = 0
    @Published var userUsage: Double = 0
    @Published var systemUsage: Double = 0
    @Published var idlePercentage: Double = 100

    private var previousInfo: host_cpu_load_info?
    private var timer: Timer?

    func start(interval: TimeInterval = 2.0) {
        previousInfo = currentCPULoadInfo()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func updateInterval(_ interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        guard let prev = previousInfo,
              let current = currentCPULoadInfo() else { return }

        let userDiff = Double(current.cpu_ticks.0 &- prev.cpu_ticks.0)
        let systemDiff = Double(current.cpu_ticks.1 &- prev.cpu_ticks.1)
        let idleDiff = Double(current.cpu_ticks.2 &- prev.cpu_ticks.2)
        let niceDiff = Double(current.cpu_ticks.3 &- prev.cpu_ticks.3)

        let totalDiff = userDiff + systemDiff + idleDiff + niceDiff
        guard totalDiff > 0 else { return }

        let newUser = (userDiff + niceDiff) / totalDiff * 100
        let newSystem = systemDiff / totalDiff * 100
        let newIdle = idleDiff / totalDiff * 100

        DispatchQueue.main.async {
            // Light smoothing to avoid jittery display
            self.userUsage = self.smooth(old: self.userUsage, new: newUser)
            self.systemUsage = self.smooth(old: self.systemUsage, new: newSystem)
            self.idlePercentage = self.smooth(old: self.idlePercentage, new: newIdle)
            self.totalUsage = 100 - self.idlePercentage
        }

        previousInfo = current
    }

    private func smooth(old: Double, new: Double, factor: Double = 0.3) -> Double {
        old * (1 - factor) + new * factor
    }

    private func currentCPULoadInfo() -> host_cpu_load_info? {
        let host = mach_host_self()
        var size = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        )
        var cpuLoadInfo = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return nil }
        return cpuLoadInfo
    }
}
