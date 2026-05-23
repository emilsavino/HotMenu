import Foundation
import SwiftUI

@Observable
final class ThermalMonitor {
    private static let pollIntervalSeconds: TimeInterval = 2.0

    private(set) var temperature: Double?
    private(set) var temperatureSource: String?
    private(set) var fanSpeed: Double?
    private(set) var hasFans: Bool = false
    private var timer: Timer?

    var showTemperatureInMenuBar: Bool = UserDefaults.standard.object(forKey: "showTemperatureInMenuBar") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showTemperatureInMenuBar, forKey: "showTemperatureInMenuBar") }
    }

    var showFanSpeedInMenuBar: Bool = UserDefaults.standard.object(forKey: "showFanSpeedInMenuBar") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showFanSpeedInMenuBar, forKey: "showFanSpeedInMenuBar") }
    }

    init() {
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMonitoring() {
        updateThermalState()

        timer = Timer.scheduledTimer(withTimeInterval: Self.pollIntervalSeconds, repeats: true) { [weak self] _ in
            self?.updateThermalState()
        }
    }

    private func updateThermalState() {
        if let smcReading = SMCReader.shared.readCPUTemperature() {
            temperature = smcReading.value
            temperatureSource = smcReading.source
        } else if let hidReading = HIDTemperatureReader.shared.readCPUTemperature() {
            temperature = hidReading.value
            temperatureSource = hidReading.source
        } else {
            temperature = nil
            temperatureSource = nil
        }

        if let fan = SMCReader.shared.readFanSpeed() {
            fanSpeed = fan.rpm
            if !hasFans { hasFans = true }
        }
    }
}
