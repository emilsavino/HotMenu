import SwiftUI

func colorForTemperature(_ temp: Double) -> Color {
    switch temp {
    case ..<60: return .green
    case 60..<80: return .yellow
    case 80..<95: return .orange
    default: return .red
    }
}

private func colorForCPU(_ percent: Double) -> Color {
    switch percent {
    case ..<60: return .green
    case 60..<85: return .orange
    default: return .red
    }
}

private func colorForMemory(_ percent: Double) -> Color {
    switch percent {
    case ..<70: return .green
    case 70..<90: return .orange
    default: return .red
    }
}

private func formatGigabytes(_ bytes: UInt64, decimals: Int) -> String {
    let gib = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
    return String(format: "%.\(decimals)f", gib)
}

struct MenuContentView: View {
    @Bindable var monitor: ThermalMonitor
    var resources: ResourceMonitor
    @Environment(\.openWindow) private var openWindow
    var openAboutAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let temp = monitor.temperature {
                    Text("\(Int(temp.rounded()))°C")
                        .foregroundColor(colorForTemperature(temp))
                        .fontWeight(.semibold)
                        .help("Source: \(monitor.temperatureSource ?? "Unknown")")
                } else {
                    Text("—°C")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let fan = monitor.fanSpeed {
                    Text("\(Int(fan.rounded())) RPM")
                        .fontWeight(.semibold)
                }
            }
            .font(.headline)

            Divider()

            resourceRow(
                label: "CPU",
                symbolName: "cpu",
                percent: resources.cpuUsage,
                trailing: nil,
                colorProvider: colorForCPU
            )

            resourceRow(
                label: "Memory",
                symbolName: "memorychip",
                percent: memoryPercent,
                trailing: memoryDetail,
                colorProvider: colorForMemory
            )

            Divider()

            Text("Settings")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Launch at Login", isOn: Binding(
                get: { LaunchAtLoginManager.shared.isEnabled },
                set: { _ in LaunchAtLoginManager.shared.toggle() }
            ))
            .controlSize(.small)

            Toggle("Show Temperature in Menu Bar", isOn: $monitor.showTemperatureInMenuBar)
                .controlSize(.small)

            if monitor.hasFans {
                Toggle("Show Fan Speed in Menu Bar", isOn: $monitor.showFanSpeedInMenuBar)
                    .controlSize(.small)
            }

            Divider()

            HStack {
                Button("About") {
                    openAboutWindow()
                }
                .controlSize(.small)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(width: 260)
    }

    private var memoryPercent: Double? {
        guard let used = resources.memoryUsedBytes, resources.memoryTotalBytes > 0 else { return nil }
        return Double(used) / Double(resources.memoryTotalBytes) * 100.0
    }

    private var memoryDetail: String? {
        guard let used = resources.memoryUsedBytes else { return nil }
        let usedString = formatGigabytes(used, decimals: 1)
        let totalString = formatGigabytes(resources.memoryTotalBytes, decimals: 0)
        return "\(usedString) / \(totalString) GB"
    }

    @ViewBuilder
    private func resourceRow(
        label: String,
        symbolName: String,
        percent: Double?,
        trailing: String?,
        colorProvider: (Double) -> Color
    ) -> some View {
        let color: Color = percent.map(colorProvider) ?? .secondary
        HStack(spacing: 8) {
            RingGauge(percent: percent ?? 0, symbolName: symbolName, color: color)
            Text(label)
                .font(.subheadline)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(percent.map { "\(Int($0.rounded()))%" } ?? "—%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }

    private func openAboutWindow() {
        if let openAboutAction {
            openAboutAction()
        } else {
            openWindow(id: "about")
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
