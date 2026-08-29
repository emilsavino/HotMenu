import SwiftUI

struct SettingsSection: View {
    @Bindable var monitor: ThermalMonitor
    @Bindable var resources: ResourceMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            launchAtLoginToggle
            temperatureToggle
            fanSpeedToggle
            cpuToggle
            gpuToggle
            memoryToggle
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

    private var cpuToggle: some View {
        Toggle("Show CPU in Menu Bar", isOn: $resources.showCPUInMenuBar)
            .controlSize(.small)
    }

    private var gpuToggle: some View {
        Toggle("Show GPU in Menu Bar", isOn: $resources.showGPUInMenuBar)
            .controlSize(.small)
    }

    private var memoryToggle: some View {
        Toggle("Show Memory in Menu Bar", isOn: $resources.showMemoryInMenuBar)
            .controlSize(.small)
    }
}
