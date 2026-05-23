import SwiftUI

struct MenuContentView: View {
    @Bindable var monitor: ThermalMonitor
    var resources: ResourceMonitor
    @Environment(\.openWindow) private var openWindow
    var openAboutAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ThermalSummaryRow(monitor: monitor)
            Divider()
            ResourceRow(
                label: "CPU",
                symbolName: "cpu",
                percent: resources.cpuUsage,
                trailing: nil,
                warningThreshold: 60,
                criticalThreshold: 85
            )
            ResourceRow(
                label: "Memory",
                symbolName: "memorychip",
                percent: memoryPercent,
                trailing: memoryDetail,
                warningThreshold: 70,
                criticalThreshold: 90
            )
            Divider()
            SettingsSection(monitor: monitor)
            Divider()
            MenuActionsRow(openAboutAction: openAboutWindow)
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

    private func openAboutWindow() {
        if let openAboutAction {
            openAboutAction()
        } else {
            openWindow(id: "about")
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

private func formatGigabytes(_ bytes: UInt64, decimals: Int) -> String {
    let gib = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
    return String(format: "%.\(decimals)f", gib)
}
