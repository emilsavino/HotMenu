import AppKit
import Observation
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let monitor: ThermalMonitor
    private let resources: ResourceMonitor
    private let openAboutAction: () -> Void
    private let checkForUpdatesAction: () -> Void
    private let popover = NSPopover()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let labelView = StatusBarLabelView()
    private let cpuLabelView = StatusBarMetricView(label: "CPU")
    private let gpuLabelView = StatusBarMetricView(label: "GPU")
    private let memoryLabelView = StatusBarMetricView(label: "MEM")
    private lazy var statusBarGroupView: NSStackView = {
        let stackView = NSStackView(views: [cpuLabelView, gpuLabelView, memoryLabelView, labelView])
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private let fallbackIcon: NSImage? = {
        let image = NSImage(systemSymbolName: "flame", accessibilityDescription: "HotMenu")
        let configured = image?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        let result = configured ?? image
        result?.isTemplate = true
        return result
    }()
    private lazy var hostingController = NSHostingController(
        rootView: MenuContentView(
            monitor: monitor,
            resources: resources,
            openAboutAction: { [weak self] in
                self?.popover.performClose(nil)
                self?.openAboutAction()
            },
            checkForUpdatesAction: { [weak self] in
                self?.popover.performClose(nil)
                self?.checkForUpdatesAction()
            }
        )
    )

    init(
        monitor: ThermalMonitor,
        resources: ResourceMonitor,
        openAboutAction: @escaping () -> Void,
        checkForUpdatesAction: @escaping () -> Void
    ) {
        self.monitor = monitor
        self.resources = resources
        self.openAboutAction = openAboutAction
        self.checkForUpdatesAction = checkForUpdatesAction
        super.init()
        configureStatusItem()
        configurePopover()
        startObservingState()
        updateStatusItems()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover(_:))
        configureAccessibility(for: button, label: "HotMenu monitoring")

        button.addSubview(statusBarGroupView)
        NSLayoutConstraint.activate([
            statusBarGroupView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            statusBarGroupView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            statusBarGroupView.topAnchor.constraint(equalTo: button.topAnchor),
            statusBarGroupView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }

    private func configureAccessibility(for button: NSButton, label: String) {
        button.toolTip = label
        button.setAccessibilityElement(true)
        button.setAccessibilityRole(.button)
        button.setAccessibilityLabel(label)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = hostingController
        updatePopoverSize()
    }

    private func updatePopoverSize() {
        hostingController.view.layoutSubtreeIfNeeded()
        popover.contentSize = hostingController.view.fittingSize
    }

    private func startObservingState() {
        withObservationTracking {
            _ = monitor.temperature
            _ = monitor.fanSpeed
            _ = monitor.showTemperatureInMenuBar
            _ = monitor.showFanSpeedInMenuBar
            _ = resources.cpuUsage
            _ = resources.gpuUsage
            _ = resources.memoryUsedBytes
            _ = resources.showCPUInMenuBar
            _ = resources.showGPUInMenuBar
            _ = resources.showMemoryInMenuBar
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateStatusItems()
                self?.startObservingState()
            }
        }
    }

    private func updateStatusItems() {
        updateThermalStatusItem()
        updateResourceStatusItems()
        updateStatusItemLayout()
        if popover.isShown {
            updatePopoverSize()
        }
    }

    private func updateThermalStatusItem() {
        let temperature = monitor.showTemperatureInMenuBar ? monitor.temperature : nil
        let fanSpeed = monitor.showFanSpeedInMenuBar ? monitor.fanSpeed : nil

        labelView.update(
            temperature: temperature,
            fanSpeed: fanSpeed
        )

        labelView.isHidden = temperature == nil && fanSpeed == nil
    }

    private func updateResourceStatusItems() {
        updateResourceStatusItem(
            labelView: cpuLabelView,
            isVisible: resources.showCPUInMenuBar,
            value: percentText(resources.cpuUsage)
        )
        updateResourceStatusItem(
            labelView: gpuLabelView,
            isVisible: resources.showGPUInMenuBar,
            value: percentText(resources.gpuUsage)
        )
        updateResourceStatusItem(
            labelView: memoryLabelView,
            isVisible: resources.showMemoryInMenuBar,
            value: percentText(memoryPercent)
        )
    }

    private func updateResourceStatusItem(
        labelView: StatusBarMetricView,
        isVisible: Bool,
        value: String
    ) {
        labelView.update(value: value)
        labelView.isHidden = !isVisible
    }

    private func updateStatusItemLayout() {
        let visibleViews = statusBarGroupView.arrangedSubviews.filter { !$0.isHidden }
        let contentWidth = visibleViews.reduce(0) { width, view in
            width + view.intrinsicContentSize.width
        }
        let spacing = CGFloat(max(0, visibleViews.count - 1)) * statusBarGroupView.spacing
        let isContentEmpty = visibleViews.isEmpty

        statusBarGroupView.isHidden = isContentEmpty
        statusItem.length = isContentEmpty
            ? NSStatusItem.squareLength
            : max(contentWidth + spacing, 8)

        if let button = statusItem.button {
            button.image = isContentEmpty ? fallbackIcon : nil
            button.setAccessibilityValue(monitoringAccessibilityValue)
        }
    }

    private var monitoringAccessibilityValue: String {
        var values: [String] = []

        if monitor.showTemperatureInMenuBar {
            if let temperature = monitor.temperature {
                values.append("\(Int(temperature.rounded())) degrees")
            } else {
                values.append("Temperature unavailable")
            }
        }
        if monitor.showFanSpeedInMenuBar {
            if let fanSpeed = monitor.fanSpeed {
                values.append("\(Int(fanSpeed.rounded())) RPM")
            } else {
                values.append("Fan speed unavailable")
            }
        }
        if resources.showCPUInMenuBar {
            values.append("CPU \(percentText(resources.cpuUsage))")
        }
        if resources.showGPUInMenuBar {
            values.append("GPU \(percentText(resources.gpuUsage))")
        }
        if resources.showMemoryInMenuBar {
            values.append("Memory \(percentText(memoryPercent))")
        }

        return values.isEmpty ? "Unavailable" : values.joined(separator: ", ")
    }

    private func percentText(_ percent: Double?) -> String {
        percent.map { "\(Int($0.rounded()))%" } ?? "—%"
    }

    private var memoryPercent: Double? {
        guard let used = resources.memoryUsedBytes, resources.memoryTotalBytes > 0 else { return nil }
        return Double(used) / Double(resources.memoryTotalBytes) * 100.0
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = sender as? NSStatusBarButton else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            updatePopoverSize()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
