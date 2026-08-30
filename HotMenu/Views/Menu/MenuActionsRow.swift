import SwiftUI

struct MenuActionsRow: View {
    let openAboutAction: () -> Void
    let checkForUpdatesAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            checkForUpdatesButton
            HStack {
                aboutButton
                Spacer()
                quitButton
            }
        }
    }

    private var checkForUpdatesButton: some View {
        Button("Check for Updates…") {
            checkForUpdatesAction()
        }
        .controlSize(.small)
    }

    private var aboutButton: some View {
        Button("About") {
            openAboutAction()
        }
        .controlSize(.small)
    }

    private var quitButton: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
        .controlSize(.small)
    }
}
