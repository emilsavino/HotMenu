import AppKit
import Observation
import SwiftUI

@main
struct HotMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ThermalMonitor()
    private var statusBarController: StatusBarController?
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(
            monitor: monitor,
            openAboutAction: { [weak self] in
                self?.showAboutWindow()
            }
        )
    }

    private func showAboutWindow() {
        if aboutWindow == nil {
            let hostingController = NSHostingController(rootView: AboutView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 280),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = hostingController
            window.isReleasedWhenClosed = false
            window.center()
            window.title = "About HotMenu"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            aboutWindow = window
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
private final class StatusBarController: NSObject {
    private let monitor: ThermalMonitor
    private let openAboutAction: () -> Void
    private let popover = NSPopover()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let labelView = StatusBarLabelView()
    private lazy var hostingController = NSHostingController(
        rootView: MenuContentView(
            monitor: monitor,
            openAboutAction: { [weak self] in
                self?.popover.performClose(nil)
                self?.openAboutAction()
            }
        )
    )

    init(monitor: ThermalMonitor, openAboutAction: @escaping () -> Void) {
        self.monitor = monitor
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
        labelView.update(
            temperature: monitor.showTemperatureInMenuBar ? monitor.temperature : nil,
            fanSpeed: monitor.showFanSpeedInMenuBar ? monitor.fanSpeed : nil
        )
        statusItem.length = max(labelView.intrinsicContentSize.width, 8)
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

private final class StatusBarLabelView: NSView {
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
