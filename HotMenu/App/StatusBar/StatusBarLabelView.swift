import AppKit

final class StatusBarLabelView: NSView {
    private static let horizontalPadding: CGFloat = 6
    private static let lineSpacing: CGFloat = -1
    private static let temperatureFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
    private static let fanFont = NSFont.monospacedDigitSystemFont(ofSize: 8, weight: .regular)

    private var temperature: Double?
    private var fanSpeed: Double?

    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        let measured = measuredLines()
        let width = measured.map(\.size.width).max() ?? 0
        return NSSize(
            width: width + Self.horizontalPadding * 2,
            height: NSStatusBar.system.thickness
        )
    }

    func update(temperature: Double?, fanSpeed: Double?) {
        self.temperature = temperature
        self.fanSpeed = fanSpeed
        invalidateIntrinsicContentSize()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let lines = measuredLines()
        guard !lines.isEmpty else { return }

        let totalHeight = lines.reduce(0) { $0 + $1.size.height } + Self.lineSpacing * CGFloat(max(0, lines.count - 1))
        var y = max(0, round((bounds.height - totalHeight) / 2))

        for line in lines {
            let x = round((bounds.width - line.size.width) / 2)
            line.text.draw(at: CGPoint(x: x, y: y))
            y += line.size.height + Self.lineSpacing
        }
    }

    private func measuredLines() -> [(text: NSAttributedString, size: NSSize)] {
        var lines: [NSAttributedString] = []

        if let temperature {
            lines.append(
                NSAttributedString(
                    string: "\(Int(temperature.rounded()))°",
                    attributes: [
                        .font: Self.temperatureFont,
                        .foregroundColor: NSColor.labelColor
                    ]
                )
            )
        }

        if let fanSpeed {
            lines.append(
                NSAttributedString(
                    string: "\(Int(fanSpeed.rounded())) RPM",
                    attributes: [
                        .font: Self.fanFont,
                        .foregroundColor: NSColor.labelColor
                    ]
                )
            )
        }

        return lines.map { attributed in
            let size = attributed.size()
            return (text: attributed, size: size)
        }
    }
}
