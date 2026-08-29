import Foundation
import IOKit

enum GPUSampler {
    private static let acceleratorClassName = "IOAccelerator"
    private static let performanceStatisticsKey = "PerformanceStatistics"
    private static let deviceUtilizationKey = "Device Utilization %"
    private static let rendererUtilizationKey = "Renderer Utilization %"
    private static let tilerUtilizationKey = "Tiler Utilization %"

    static func sampleUsage() -> Double? {
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching(acceleratorClassName) else { return nil }

        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var usages: [Double] = []

        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            guard let properties = copyProperties(for: service),
                  let statistics = properties[performanceStatisticsKey] as? NSDictionary,
                  let usage = utilization(in: statistics) else {
                continue
            }

            usages.append(usage)
        }

        // A Mac can expose more than one accelerator. The menu has one GPU
        // gauge, so show the busiest accelerator instead of averaging devices
        // with potentially different capacities.
        return usages.max()
    }

    private static func copyProperties(for service: io_registry_entry_t) -> NSDictionary? {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(
            service,
            &properties,
            kCFAllocatorDefault,
            0
        )

        guard result == KERN_SUCCESS, let properties else { return nil }
        return properties.takeRetainedValue() as NSDictionary
    }

    private static func utilization(in statistics: NSDictionary) -> Double? {
        let keys = [
            deviceUtilizationKey,
            rendererUtilizationKey,
            tilerUtilizationKey
        ]

        for key in keys {
            guard let number = statistics[key] as? NSNumber else { continue }
            let value = number.doubleValue
            guard value.isFinite else { continue }
            return min(max(value, 0), 100)
        }

        return nil
    }
}
