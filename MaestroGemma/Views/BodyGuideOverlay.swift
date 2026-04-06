import SwiftUI

struct BodyGuideOverlay: View {
    let bodyDetected: Bool

    var body: some View {
        ZStack {
            if !bodyDetected {
                // Guide frame showing where to position
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 80)

                    // Silhouette region
                    ZStack {
                        // Dashed outline for upper body region
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 220, height: 320)

                        VStack(spacing: 8) {
                            // Head marker
                            Circle()
                                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 50, height: 50)

                            // Shoulder line
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 120, height: 2)

                            // Torso guide
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                .frame(width: 80, height: 140)

                            Spacer().frame(height: 20)
                        }
                    }

                    Text("Position your upper body in the frame")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Text("Hold your violin in playing position")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: bodyDetected)
        .allowsHitTesting(false)
    }
}
