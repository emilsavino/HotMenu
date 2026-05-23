import Darwin
import Foundation
import Observation

@Observable
@MainActor
final class ResourceMonitor {
    private static let pollIntervalSeconds: TimeInterval = 2.0
    private static let cpuPrimeDelaySeconds: TimeInterval = 0.2

    private(set) var cpuUsage: Double?
    private(set) var memoryUsedBytes: UInt64?
    let memoryTotalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory

    private var timer: Timer?
    private var previousCPUTicks: CPUTicks?

    init() {
        start()
    }

    private func start() {
        sampleMemory()
        previousCPUTicks = CPUSampler.sample()

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.cpuPrimeDelaySeconds * 1_000_000_000))
            self?.tick()
        }

        timer = Timer.scheduledTimer(withTimeInterval: Self.pollIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        sampleCPU()
        sampleMemory()
    }

    private func sampleCPU() {
        guard let current = CPUSampler.sample() else { return }
        defer { previousCPUTicks = current }

        guard let previous = previousCPUTicks else { return }

        let userDelta = current.user &- previous.user
        let systemDelta = current.system &- previous.system
        let niceDelta = current.nice &- previous.nice
        let idleDelta = current.idle &- previous.idle

        let busy = userDelta &+ systemDelta &+ niceDelta
        let total = busy &+ idleDelta
        guard total > 0 else { return }

        cpuUsage = (Double(busy) / Double(total)) * 100.0
    }

    private func sampleMemory() {
        guard let used = MemorySampler.sampleUsedBytes() else { return }
        memoryUsedBytes = used
    }
}

struct CPUTicks {
    var user: UInt64
    var system: UInt64
    var idle: UInt64
    var nice: UInt64
}

private enum CPUSampler {
    static func sample() -> CPUTicks? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        )

        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        var totals = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        let stride = Int(CPU_STATE_MAX)

        for cpu in 0..<Int(cpuCount) {
            let base = cpu * stride
            totals.user &+= UInt64(info[base + Int(CPU_STATE_USER)])
            totals.system &+= UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            totals.idle &+= UInt64(info[base + Int(CPU_STATE_IDLE)])
            totals.nice &+= UInt64(info[base + Int(CPU_STATE_NICE)])
        }

        return totals
    }
}

private enum MemorySampler {
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
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        return active &+ wired &+ compressed
    }
}
