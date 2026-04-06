import SwiftUI

struct CoachingOverlayView: View {
    let text: String
    let source: RoutingTarget

    private var sourceLabel: String {
        source == .localServer ? "Gemma 4 · 27B · Mac Studio" : "Gemma 4 · E2B · On-Device"
    }

    private var sourceColor: Color {
        source == .localServer ? .blue : .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(sourceColor)
                    .frame(width: 6, height: 6)

                Text(sourceLabel)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(sourceColor.opacity(0.9))

                Spacer()
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
