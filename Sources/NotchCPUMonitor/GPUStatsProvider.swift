import Foundation
import IOKit

final class GPUStatsProvider: ObservableObject {
    @Published var utilization: Double = 0

    func update() {
        guard let usage = readGPUUtilization() else { return }
        DispatchQueue.main.async {
            self.utilization = self.smooth(old: self.utilization, new: usage)
        }
    }

    private func smooth(old: Double, new: Double, factor: Double = 0.3) -> Double {
        old * (1 - factor) + new * factor
    }

    private func readGPUUtilization() -> Double? {
        var iterator: io_iterator_t = 0
        let matchDict = IOServiceMatching("IOAccelerator")

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var entry: io_registry_entry_t = IOIteratorNext(iterator)
        defer { if entry != 0 { IOObjectRelease(entry) } }

        while entry != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = properties?.takeRetainedValue() as? [String: Any] else {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
                continue
            }

            if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                // Apple Silicon reports "Device Utilization %" directly
                if let deviceUtil = perfStats["Device Utilization %"] as? NSNumber {
                    return deviceUtil.doubleValue
                }
                // Fallback: try GPU Activity
                if let gpuActivity = perfStats["GPU Activity(%)"] as? NSNumber {
                    return gpuActivity.doubleValue
                }
                // Another fallback for Intel Macs
                if let gpuUtil = perfStats["GPU Core Utilization"] as? NSNumber {
                    return gpuUtil.doubleValue * 100.0
                }
            }

            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }

        return nil
    }
}
