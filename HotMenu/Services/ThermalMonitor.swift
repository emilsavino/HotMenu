import Foundation
import SwiftUI

@MainActor
@Observable
final class ThermalMonitor {
    private static let pollIntervalSeconds: TimeInterval = 2.0

    private(set) var temperature: Double?
    private(set) var temperatureSource: String?
    private(set) var fanSpeed: Double?
    private(set) var hasFans: Bool = false
    private var samplingTask: Task<Void, Never>?

    var showTemperatureInMenuBar: Bool = UserDefaults.standard.object(forKey: "showTemperatureInMenuBar") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showTemperatureInMenuBar, forKey: "showTemperatureInMenuBar") }
    }

    var showFanSpeedInMenuBar: Bool = UserDefaults.standard.object(forKey: "showFanSpeedInMenuBar") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showFanSpeedInMenuBar, forKey: "showFanSpeedInMenuBar") }
    }

    init() {
        startMonitoring()
    }

    private func startMonitoring() {
        let sampler = ThermalSampler()

        samplingTask = Task { @MainActor [weak self, sampler] in
            while !Task.isCancelled {
                let snapshot = await sampler.sample()
                guard !Task.isCancelled else { return }
                guard self != nil else { return }
                self?.apply(snapshot)

                do {
                    try await Task.sleep(nanoseconds: UInt64(Self.pollIntervalSeconds * 1_000_000_000))
                } catch {
                    // Task cancellation stops the sampling loop.
                    return
                }
            }
        }
    }

    private func apply(_ snapshot: ThermalSnapshot) {
        temperature = snapshot.temperature
        temperatureSource = snapshot.temperatureSource

        if let fanSpeed = snapshot.fanSpeed {
            self.fanSpeed = fanSpeed
            hasFans = true
        }
    }
}

private struct ThermalSnapshot: Sendable {
    let temperature: Double?
    let temperatureSource: String?
    let fanSpeed: Double?
}

private actor ThermalSampler {
    func sample() -> ThermalSnapshot {
        let temperatureReading = SMCReader.shared.readCPUTemperature()
            ?? HIDTemperatureReader.shared.readCPUTemperature()

        return ThermalSnapshot(
            temperature: temperatureReading?.value,
            temperatureSource: temperatureReading?.source,
            fanSpeed: SMCReader.shared.readFanSpeed()?.rpm
        )
    }
}
