import Foundation
import Observation

@Observable
@MainActor
final class ResourceMonitor {
    private static let pollIntervalSeconds: TimeInterval = 2.0
    private static let cpuPrimeDelaySeconds: TimeInterval = 0.2

    private(set) var cpuUsage: Double?
    private(set) var gpuUsage: Double?
    private(set) var memoryUsedBytes: UInt64?
    let memoryTotalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory

    var showCPUInMenuBar: Bool = UserDefaults.standard.object(forKey: "showCPUInMenuBar") as? Bool ?? false {
        didSet { UserDefaults.standard.set(showCPUInMenuBar, forKey: "showCPUInMenuBar") }
    }

    var showGPUInMenuBar: Bool = UserDefaults.standard.object(forKey: "showGPUInMenuBar") as? Bool ?? false {
        didSet { UserDefaults.standard.set(showGPUInMenuBar, forKey: "showGPUInMenuBar") }
    }

    var showMemoryInMenuBar: Bool = UserDefaults.standard.object(forKey: "showMemoryInMenuBar") as? Bool ?? false {
        didSet { UserDefaults.standard.set(showMemoryInMenuBar, forKey: "showMemoryInMenuBar") }
    }

    private var samplingTask: Task<Void, Never>?

    init() {
        start()
    }

    private func start() {
        let sampler = ResourceSampler()

        samplingTask = Task { @MainActor [weak self, sampler] in
            let initialSnapshot = await sampler.sample()
            guard !Task.isCancelled else { return }
            guard self != nil else { return }
            self?.apply(initialSnapshot)

            do {
                try await Task.sleep(nanoseconds: UInt64(Self.cpuPrimeDelaySeconds * 1_000_000_000))

                while !Task.isCancelled {
                    let snapshot = await sampler.sample()
                    guard !Task.isCancelled else { return }
                    guard self != nil else { return }
                    self?.apply(snapshot)
                    try await Task.sleep(nanoseconds: UInt64(Self.pollIntervalSeconds * 1_000_000_000))
                }
            } catch {
                // Task cancellation stops the sampling loop.
            }
        }
    }

    private func apply(_ snapshot: ResourceSnapshot) {
        cpuUsage = snapshot.cpuUsage
        gpuUsage = snapshot.gpuUsage
        memoryUsedBytes = snapshot.memoryUsedBytes
    }
}

private struct ResourceSnapshot: Sendable {
    let cpuUsage: Double?
    let gpuUsage: Double?
    let memoryUsedBytes: UInt64?
}

private actor ResourceSampler {
    private var previousCPUTicks: CPUTicks?
    private var cpuUsage: Double?
    private var gpuUsage: Double?
    private var memoryUsedBytes: UInt64?

    func sample() -> ResourceSnapshot {
        if let cpuUsage = sampleCPU() {
            self.cpuUsage = cpuUsage
        }
        if let gpuUsage = GPUSampler.sampleUsage() {
            self.gpuUsage = gpuUsage
        }
        if let memoryUsedBytes = MemorySampler.sampleUsedBytes() {
            self.memoryUsedBytes = memoryUsedBytes
        }

        return ResourceSnapshot(
            cpuUsage: cpuUsage,
            gpuUsage: gpuUsage,
            memoryUsedBytes: memoryUsedBytes
        )
    }

    private func sampleCPU() -> Double? {
        guard let current = CPUSampler.sample() else { return nil }
        defer { previousCPUTicks = current }

        guard let previous = previousCPUTicks else { return nil }

        let userDelta = current.user &- previous.user
        let systemDelta = current.system &- previous.system
        let niceDelta = current.nice &- previous.nice
        let idleDelta = current.idle &- previous.idle

        let busy = userDelta &+ systemDelta &+ niceDelta
        let total = busy &+ idleDelta
        guard total > 0 else { return nil }

        return (Double(busy) / Double(total)) * 100.0
    }
}
