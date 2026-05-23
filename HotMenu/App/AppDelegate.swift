import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ThermalMonitor()
    private let resources = ResourceMonitor()
    private var statusBarController: StatusBarController?
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(
            monitor: monitor,
            resources: resources,
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
