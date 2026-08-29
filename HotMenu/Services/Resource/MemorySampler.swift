import Darwin
import Foundation

enum MemorySampler {
    static func sampleUsedBytes() -> UInt64? {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        var rawPageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &rawPageSize) == KERN_SUCCESS else { return nil }
        let pageSize = UInt64(rawPageSize)

        // Activity Monitor's "Memory Used" is not the sum of the active,
        // wired, and compressor queues. That sum leaves out memory that is
        // resident but not represented by those three counters. Calculate
        // the used portion as the physical-memory complement of free and
        // reclaimable file-backed pages instead.
        let freePages = stats.free_count >= stats.speculative_count
            ? UInt64(stats.free_count - stats.speculative_count)
            : 0
        let cachedPages = UInt64(stats.external_page_count) &+
            UInt64(stats.purgeable_count)
        let reclaimableBytes = (freePages &+ cachedPages) &* pageSize
        let physicalMemory = ProcessInfo.processInfo.physicalMemory

        return physicalMemory >= reclaimableBytes
            ? physicalMemory - reclaimableBytes
            : 0
    }
}
