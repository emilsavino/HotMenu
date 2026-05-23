import SwiftUI

struct MenuActionsRow: View {
    let openAboutAction: () -> Void

    var body: some View {
        HStack {
            aboutButton
            Spacer()
            quitButton
        }
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
