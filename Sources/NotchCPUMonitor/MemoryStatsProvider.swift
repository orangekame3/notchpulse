import Foundation
import Darwin

final class MemoryStatsProvider: ObservableObject {
    @Published var usedGB: Double = 0
    @Published var totalGB: Double = 0
    @Published var usagePercent: Double = 0
    @Published var appMemoryGB: Double = 0
    @Published var wiredGB: Double = 0
    @Published var compressedGB: Double = 0

    private let totalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory
    private let pageSize: Double = Double(vm_kernel_page_size)

    init() {
        totalGB = Double(totalBytes) / 1_073_741_824
    }

    func update() {
        let host = mach_host_self()
        var size = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        )
        var stats = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        // App memory = internal - purgeable (approximation: active + wired part used by apps)
        let appMem = active

        let used = active + wired + compressed
        let total = Double(totalBytes)

        DispatchQueue.main.async {
            self.usedGB = used / 1_073_741_824
            self.usagePercent = (used / total) * 100
            self.appMemoryGB = appMem / 1_073_741_824
            self.wiredGB = wired / 1_073_741_824
            self.compressedGB = compressed / 1_073_741_824
        }
    }
}
