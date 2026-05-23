import SwiftUI

struct ResourceRow: View {
    let label: String
    let symbolName: String
    let percent: Double?
    let trailing: String?
    let warningThreshold: Double
    let criticalThreshold: Double

    var body: some View {
        HStack(spacing: 8) {
            RingGauge(percent: percent ?? 0, symbolName: symbolName, color: color)
            Text(label).font(.subheadline)
            Spacer()
            trailingText
            percentText
        }
    }

    private var color: Color {
        guard let percent else { return .secondary }
        switch percent {
        case ..<warningThreshold: return .green
        case ..<criticalThreshold: return .orange
        default: return .red
        }
    }

    private var percentText: some View {
        Text(percent.map { "\(Int($0.rounded()))%" } ?? "—%")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .monospacedDigit()
    }

    @ViewBuilder
    private var trailingText: some View {
        if let trailing {
            Text(trailing)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
