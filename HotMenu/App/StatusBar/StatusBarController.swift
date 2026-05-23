import AppKit
import Observation
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let monitor: ThermalMonitor
    private let resources: ResourceMonitor
    private let openAboutAction: () -> Void
    private let popover = NSPopover()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let labelView = StatusBarLabelView()
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
        configureStatusItem()
        configurePopover()
        startObservingMonitor()
        updateStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover(_:))

        labelView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(labelView)
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            labelView.topAnchor.constraint(equalTo: button.topAnchor),
            labelView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
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

    private func startObservingMonitor() {
        withObservationTracking {
            _ = monitor.temperature
            _ = monitor.fanSpeed
            _ = monitor.showTemperatureInMenuBar
            _ = monitor.showFanSpeedInMenuBar
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateStatusItem()
                self?.startObservingMonitor()
            }
        }
    }

    private func updateStatusItem() {
        let temperature = monitor.showTemperatureInMenuBar ? monitor.temperature : nil
        let fanSpeed = monitor.showFanSpeedInMenuBar ? monitor.fanSpeed : nil

        labelView.update(
            temperature: temperature,
            fanSpeed: fanSpeed
        )

        let isMenuBarContentEmpty = temperature == nil && fanSpeed == nil

        if let button = statusItem.button {
            labelView.isHidden = isMenuBarContentEmpty
            button.image = isMenuBarContentEmpty ? fallbackIcon : nil
        }

        statusItem.length = isMenuBarContentEmpty
            ? NSStatusItem.squareLength
            : max(labelView.intrinsicContentSize.width, 8)
        updatePopoverSize()
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            updatePopoverSize()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
