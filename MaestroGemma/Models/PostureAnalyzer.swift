import Vision
import AVFoundation
import UIKit

// Manages Apple Vision body pose detection at 30fps
class PostureAnalyzer: NSObject, ObservableObject {
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var postureIssues: [String] = []
    @Published var bodyDetected = false

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

        let detected = normalized.count >= 4 // need at least shoulders + elbows
        DispatchQueue.main.async {
            self.bodyPoints = normalized
            self.postureIssues = issues
            self.bodyDetected = detected
        }
    }

    // Detect common beginner violin posture issues
    private func detectIssues(from observation: VNHumanBodyPoseObservation) -> [String] {
        guard let points = try? observation.recognizedPoints(.all) else { return [] }
        var issues: [String] = []

        let rightShoulder = points[.rightShoulder]
        let leftShoulder = points[.leftShoulder]
        let rightElbow = points[.rightElbow]
        let leftElbow = points[.leftElbow]
        let rightWrist = points[.rightWrist]
        let leftWrist = points[.leftWrist]
        let nose = points[.nose]
        let neck = points[.neck]
        let rightHip = points[.rightHip]
        let leftHip = points[.leftHip]

        // 1. Raised bow shoulder (right shoulder higher than left)
        if let rs = rightShoulder, let ls = leftShoulder,
           rs.confidence > 0.5, ls.confidence > 0.5 {
            let diff = rs.location.y - ls.location.y
            if diff > 0.04 {
                issues.append("raisedBowShoulder")
            }
        }

        // 2. Bow elbow too low (elbow drops below shoulder level significantly)
        if let re = rightElbow, let rs = rightShoulder,
           re.confidence > 0.5, rs.confidence > 0.5 {
            let diff = rs.location.y - re.location.y
            if diff > 0.12 {
                issues.append("lowBowElbow")
            }
        }

        // 3. Head not tilted toward violin (chin rest posture)
        // When playing, the head should tilt slightly left toward the chin rest
        if let n = nose, let nk = neck,
           n.confidence > 0.5, nk.confidence > 0.5 {
            let headOffset = n.location.x - nk.location.x
            // Positive offset = head tilted right (away from violin) — bad
            if headOffset > 0.06 {
                issues.append("headTiltedAway")
            }
        }

        // 4. Collapsed left wrist (wrist bends inward toward fingerboard)
        // Left wrist should stay roughly in line between elbow and hand
        if let lw = leftWrist, let le = leftElbow, let ls = leftShoulder,
           lw.confidence > 0.5, le.confidence > 0.5, ls.confidence > 0.5 {
            // If wrist drops significantly below the elbow-shoulder line
            let elbowToShoulderY = ls.location.y - le.location.y
            let elbowToWristY = le.location.y - lw.location.y
            if elbowToShoulderY > 0 && elbowToWristY > 0.08 {
                issues.append("collapsedLeftWrist")
            }
        }

        // 5. Body leaning (torso should be upright)
        if let nk = neck, let rh = rightHip, let lh = leftHip,
           nk.confidence > 0.5, rh.confidence > 0.4, lh.confidence > 0.4 {
            let hipCenter = CGPoint(x: (rh.location.x + lh.location.x) / 2,
                                    y: (rh.location.y + lh.location.y) / 2)
            let lean = abs(nk.location.x - hipCenter.x)
            if lean > 0.08 {
                issues.append("bodyLeaning")
            }
        }

        return issues
    }
}
