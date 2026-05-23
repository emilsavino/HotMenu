import SwiftUI

struct ThermalSummaryRow: View {
    let monitor: ThermalMonitor

    var body: some View {
        HStack {
            temperature
            Spacer()
            fanSpeed
        }
        .font(.headline)
    }

    @ViewBuilder
    private var temperature: some View {
        if let temp = monitor.temperature {
            Text("\(Int(temp.rounded()))°C")
                .foregroundColor(colorForTemperature(temp))
                .fontWeight(.semibold)
                .help("Source: \(monitor.temperatureSource ?? "Unknown")")
        } else {
            Text("—°C")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var fanSpeed: some View {
        if let fan = monitor.fanSpeed {
            Text("\(Int(fan.rounded())) RPM")
                .fontWeight(.semibold)
        }
    }
}

private func colorForTemperature(_ temp: Double) -> Color {
    switch temp {
    case ..<60: return .green
    case 60..<80: return .yellow
    case 80..<95: return .orange
    default: return .red
    }
}
