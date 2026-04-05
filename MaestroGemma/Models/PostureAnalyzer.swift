import Vision
import AVFoundation
import UIKit

// Manages Apple Vision body pose detection at 30fps
class PostureAnalyzer: NSObject, ObservableObject {
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var postureIssues: [String] = []

    private var lastAnalysisTime = Date.distantPast
    private let analysisInterval: TimeInterval = 1.0 // analyze every 1s for coaching

    func analyze(sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
            guard let observation = request.results?.first as? VNHumanBodyPoseObservation else { return }
            self?.processObservation(observation)
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation)
        try? handler.perform([request])
    }

    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        guard let points = try? observation.recognizedPoints(.all) else { return }

        var normalized: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in points where point.confidence > 0.3 {
            normalized[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }

        let issues = detectIssues(from: observation)

        DispatchQueue.main.async {
            self.bodyPoints = normalized
            self.postureIssues = issues
        }
    }

    // Detect common beginner violin posture issues
    private func detectIssues(from observation: VNHumanBodyPoseObservation) -> [String] {
        guard let points = try? observation.recognizedPoints(.all) else { return [] }
        var issues: [String] = []

        let rightShoulder = points[.rightShoulder]
        let leftShoulder = points[.leftShoulder]
        let rightElbow = points[.rightElbow]

        // Raised bow shoulder (right shoulder higher than left)
        if let rs = rightShoulder, let ls = leftShoulder,
           rs.confidence > 0.5, ls.confidence > 0.5 {
            let diff = rs.location.y - ls.location.y
            if diff > 0.04 {
                issues.append("raisedBowShoulder")
            }
        }

        // Bow elbow too low (elbow drops below shoulder level significantly)
        if let re = rightElbow, let rs = rightShoulder,
           re.confidence > 0.5, rs.confidence > 0.5 {
            let diff = rs.location.y - re.location.y
            if diff > 0.12 {
                issues.append("lowBowElbow")
            }
        }

        return issues
    }
}
