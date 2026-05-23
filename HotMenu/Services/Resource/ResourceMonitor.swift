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
