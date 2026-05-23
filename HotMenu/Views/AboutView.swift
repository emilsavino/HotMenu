import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            icon
            title
            version
            description
        }
        .padding(32)
        .frame(width: 320)
    }

    private var icon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 128, height: 128)
            .cornerRadius(24)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
    }

    private var title: some View {
        Text("HotMenu")
            .font(.title)
            .fontWeight(.bold)
    }

    private var version: some View {
        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var description: some View {
        Text("Monitor your Mac's temperature and fan activity.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
}
