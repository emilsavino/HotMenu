import SwiftUI

struct RingGauge: View {
    let percent: Double
    let symbolName: String
    let color: Color

    private static let diameter: CGFloat = 32
    private static let stroke: CGFloat = 2
    private static let symbolSize: CGFloat = 15
    private static let trackOpacity: Double = 0.2

    private var fraction: Double {
        min(max(percent / 100.0, 0), 1)
    }

    var body: some View {
        ZStack {
            track
            filledArc
            symbol
        }
        .frame(width: Self.diameter, height: Self.diameter)
    }

    private var track: some View {
        Circle()
            .stroke(
                Color.secondary.opacity(Self.trackOpacity),
                style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round)
            )
    }

    private var filledArc: some View {
        Circle()
            .trim(from: 0, to: fraction)
            .stroke(color, style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.4), value: fraction)
    }

    private var symbol: some View {
        Image(systemName: symbolName)
            .font(.system(size: Self.symbolSize, weight: .regular))
            .foregroundStyle(.primary)
    }
}

#Preview {
    RingGauge(percent: 30, symbolName: "memorychip", color: .green)
}
