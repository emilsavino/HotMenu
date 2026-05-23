import SwiftUI

func colorForTemperature(_ temp: Double) -> Color {
    switch temp {
    case ..<60: return .green
    case 60..<80: return .yellow
    case 80..<95: return .orange
    default: return .red
    }
}

struct MenuContentView: View {
    @Bindable var monitor: ThermalMonitor
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

    private func openAboutWindow() {
        if let openAboutAction {
            openAboutAction()
        } else {
            openWindow(id: "about")
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
