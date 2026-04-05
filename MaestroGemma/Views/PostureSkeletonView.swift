import SwiftUI
import Vision

struct PostureSkeletonView: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.rightHip, .rightKnee),
        (.neck, .leftShoulder), (.neck, .rightShoulder)
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw bones
                for (a, b) in connections {
                    guard let pa = bodyPoints[a], let pb = bodyPoints[b] else { continue }
                    let ptA = CGPoint(x: pa.x * size.width, y: pa.y * size.height)
                    let ptB = CGPoint(x: pb.x * size.width, y: pb.y * size.height)
                    var path = Path()
                    path.move(to: ptA)
                    path.addLine(to: ptB)
                    context.stroke(path, with: .color(.green.opacity(0.8)), lineWidth: 2.5)
                }
                // Draw joints
                for (_, point) in bodyPoints {
                    let pt = CGPoint(x: point.x * size.width, y: point.y * size.height)
                    let rect = CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.9)))
                }
            }
        }
    }
}
