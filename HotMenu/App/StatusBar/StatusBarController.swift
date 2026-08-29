import AppKit
import Observation
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let monitor: ThermalMonitor
    private let resources: ResourceMonitor
    private let openAboutAction: () -> Void
    private let popover = NSPopover()
    private let thermalStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let cpuStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let gpuStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let memoryStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let labelView = StatusBarLabelView()
    private let cpuLabelView = StatusBarMetricView(label: "CPU")
    private let gpuLabelView = StatusBarMetricView(label: "GPU")
    private let memoryLabelView = StatusBarMetricView(label: "MEM")
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
            }
        )
    )

    init(monitor: ThermalMonitor, resources: ResourceMonitor, openAboutAction: @escaping () -> Void) {
        self.monitor = monitor
        self.resources = resources
        self.openAboutAction = openAboutAction
        super.init()
        configureThermalStatusItem()
        configureResourceStatusItem(
            cpuStatusItem,
            labelView: cpuLabelView,
            accessibilityLabel: "CPU usage"
        )
        configureResourceStatusItem(
            gpuStatusItem,
            labelView: gpuLabelView,
            accessibilityLabel: "GPU usage"
        )
        configureResourceStatusItem(
            memoryStatusItem,
            labelView: memoryLabelView,
            accessibilityLabel: "Memory usage"
        )
        configurePopover()
        startObservingState()
        updateStatusItems()
    }

    private func configureThermalStatusItem() {
        guard let button = thermalStatusItem.button else { return }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover(_:))
        configureAccessibility(for: button, label: "CPU temperature and fan speed")

        labelView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(labelView)
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            labelView.topAnchor.constraint(equalTo: button.topAnchor),
            labelView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }

    private func configureResourceStatusItem(
        _ statusItem: NSStatusItem,
        labelView: StatusBarMetricView,
        accessibilityLabel: String
    ) {
        guard let button = statusItem.button else { return }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover(_:))
        configureAccessibility(for: button, label: accessibilityLabel)

        labelView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(labelView)
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            labelView.topAnchor.constraint(equalTo: button.topAnchor),
            labelView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        statusItem.isVisible = false
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

        let isMenuBarContentEmpty = temperature == nil && fanSpeed == nil

        if let button = thermalStatusItem.button {
            labelView.isHidden = isMenuBarContentEmpty
            button.image = isMenuBarContentEmpty ? fallbackIcon : nil
            button.setAccessibilityValue(thermalAccessibilityValue)
        }

        thermalStatusItem.length = isMenuBarContentEmpty
            ? NSStatusItem.squareLength
            : max(labelView.intrinsicContentSize.width, 8)
    }

    private func updateResourceStatusItems() {
        updateResourceStatusItem(
            cpuStatusItem,
            labelView: cpuLabelView,
            isVisible: resources.showCPUInMenuBar,
            value: percentText(resources.cpuUsage)
        )
        updateResourceStatusItem(
            gpuStatusItem,
            labelView: gpuLabelView,
            isVisible: resources.showGPUInMenuBar,
            value: percentText(resources.gpuUsage)
        )
        updateResourceStatusItem(
            memoryStatusItem,
            labelView: memoryLabelView,
            isVisible: resources.showMemoryInMenuBar,
            value: percentText(memoryPercent)
        )
    }

    private func updateResourceStatusItem(
        _ statusItem: NSStatusItem,
        labelView: StatusBarMetricView,
        isVisible: Bool,
        value: String
    ) {
        labelView.update(value: value)
        statusItem.button?.setAccessibilityValue(value)
        statusItem.length = max(labelView.intrinsicContentSize.width, 8)
        statusItem.isVisible = isVisible
    }

    private var thermalAccessibilityValue: String {
        var values: [String] = []

        if monitor.showTemperatureInMenuBar, let temperature = monitor.temperature {
            values.append("\(Int(temperature.rounded())) degrees")
        }
        if monitor.showFanSpeedInMenuBar, let fanSpeed = monitor.fanSpeed {
            values.append("\(Int(fanSpeed.rounded())) RPM")
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
