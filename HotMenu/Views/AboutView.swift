import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            if #available(macOS 26.0, *) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(24)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
            } else {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(24)
            }

            Text("HotMenu")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Monitor your Mac's temperature and fan activity.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 320)
    }
}
