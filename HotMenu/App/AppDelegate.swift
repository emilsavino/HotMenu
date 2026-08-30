import AppKit
import Sparkle
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ThermalMonitor()
    private let resources = ResourceMonitor()
    private var statusBarController: StatusBarController?
    private var aboutWindow: NSWindow?
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force initialization so automatic checks start before the first manual check.
        _ = updaterController
        configureApplicationMenu()
        statusBarController = StatusBarController(
            monitor: monitor,
            resources: resources,
            openAboutAction: { [weak self] in
                self?.showAboutWindow()
            },
            checkForUpdatesAction: { [weak self] in
                self?.checkForUpdates(nil)
            }
        )
    }

    private func configureApplicationMenu() {
        guard let applicationMenu = NSApp.mainMenu?.item(at: 0)?.submenu,
              !applicationMenu.items.contains(where: { $0.title == "Check for Updates…" }) else {
            return
        }

        applicationMenu.addItem(.separator())

        let checkForUpdatesItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )
        checkForUpdatesItem.target = self
        applicationMenu.addItem(checkForUpdatesItem)
    }

    @objc
    private func checkForUpdates(_ sender: Any?) {
        updaterController.checkForUpdates(nil)
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
