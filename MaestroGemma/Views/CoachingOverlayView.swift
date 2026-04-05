import SwiftUI

struct CoachingOverlayView: View {
    let text: String
    let source: RoutingTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill.checkmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(source == .localServer ? "Maestro (Studio)" : "Maestro")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                if source == .localServer {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .accessibilityLabel("Deep analysis mode")
                }
            }

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Coach says: \(text)")
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.bottom, 12)
        .animation(.easeInOut(duration: 0.3), value: text)
    }
}
