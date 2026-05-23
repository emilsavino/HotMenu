import SwiftUI

struct SettingsSection: View {
    @Bindable var monitor: ThermalMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            launchAtLoginToggle
            temperatureToggle
            fanSpeedToggle
        }
    }

    private var header: some View {
        Text("Settings")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var launchAtLoginToggle: some View {
        Toggle("Launch at Login", isOn: Binding(
            get: { LaunchAtLoginManager.shared.isEnabled },
            set: { _ in LaunchAtLoginManager.shared.toggle() }
        ))
        .controlSize(.small)
    }

    private var temperatureToggle: some View {
        Toggle("Show Temperature in Menu Bar", isOn: $monitor.showTemperatureInMenuBar)
            .controlSize(.small)
    }

    @ViewBuilder
    private var fanSpeedToggle: some View {
        if monitor.hasFans {
            Toggle("Show Fan Speed in Menu Bar", isOn: $monitor.showFanSpeedInMenuBar)
                .controlSize(.small)
        }
    }
}
