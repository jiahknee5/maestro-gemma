import SwiftUI

struct PitchDisplayView: View {
    let note: String
    let cents: Int

    private var centsColor: Color {
        let abs = Swift.abs(cents)
        if abs <= 10 { return .green }
        if abs <= 20 { return .yellow }
        return .red
    }

    private var centsLabel: String {
        if note == "—" { return "" }
        if cents == 0 { return "in tune" }
        return cents > 0 ? "+\(cents)¢" : "\(cents)¢"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(note)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .accessibilityLabel("Current note: \(note)")

            if note != "—" {
                VStack(spacing: 2) {
                    Text(centsLabel)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(centsColor)

                    // Cents bar
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 5)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(centsColor)
                            .frame(width: 4, height: 10)
                            .offset(x: CGFloat(cents).clamped(-50, 50) * 0.8)
                    }
                }
                .accessibilityLabel("\(Swift.abs(cents)) cents \(cents >= 0 ? "sharp" : "flat")")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

extension Comparable {
    func clamped(_ lower: Self, _ upper: Self) -> Self {
        return min(max(self, lower), upper)
    }
}
